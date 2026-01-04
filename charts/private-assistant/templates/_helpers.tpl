{{/*
Expand the name of the chart.
*/}}
{{- define "private-assistant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "private-assistant.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "private-assistant.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "private-assistant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "private-assistant.labels" -}}
helm.sh/chart: {{ include "private-assistant.chart" . }}
{{ include "private-assistant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "private-assistant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "private-assistant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "private-assistant.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "private-assistant.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "private-assistant.groundStationConfig" -}}
speech_synthesis_api: {{ if .Values.groundStation.ttsServiceHostOverwrite }}{{ .Values.groundStation.ttsServiceHostOverwrite }}{{ else }}http://{{ .Release.Name }}-tts-engine.{{ .Release.Namespace }}.svc{{ if ne .Values.clusterDomain "" }}.{{ .Values.clusterDomain }}/synthesizeSpeech{{ end }}{{ end }}
speech_synthesis_api_token: {{ if .Values.groundStation.ttsServiceTokenOverwrite }}{{ .Values.groundStation.ttsServiceTokenOverwrite }}{{ else }}{{ .Values.ttsEngine.config.allowedUserToken }}{{ end }}
{{- end -}}

{{/*
Generic service template
Usage: include "private-assistant.service" (dict "component" "ground-station" "context" $)
*/}}
{{- define "private-assistant.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "private-assistant.fullname" .context }}-{{ .component }}
  labels:
    {{- include "private-assistant.labels" .context | nindent 4 }}
spec:
  type: {{ .serviceType }}
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/component: {{ .component }}
    {{- include "private-assistant.selectorLabels" .context | nindent 4 }}
{{- end -}}

{{/*
Generic ingress template
Usage: include "private-assistant.ingress" (dict "component" "ground-station" "serviceName" "ground-station" "config" .Values.groundStation.ingress "context" $)
*/}}
{{- define "private-assistant.ingress" -}}
{{- $fullName := include "private-assistant.fullname" .context -}}
{{- if and .config.className (not (semverCompare ">=1.18-0" .context.Capabilities.KubeVersion.GitVersion)) }}
  {{- if not (hasKey .config.annotations "kubernetes.io/ingress.class") }}
  {{- $_ := set .config.annotations "kubernetes.io/ingress.class" .config.className}}
  {{- end }}
{{- end }}
{{- if semverCompare ">=1.19-0" .context.Capabilities.KubeVersion.GitVersion -}}
apiVersion: networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .context.Capabilities.KubeVersion.GitVersion -}}
apiVersion: networking.k8s.io/v1beta1
{{- else -}}
apiVersion: extensions/v1beta1
{{- end }}
kind: Ingress
metadata:
  name: {{ $fullName }}{{ if ne .nameSuffix "" }}-{{ .nameSuffix }}{{ end }}
  labels:
    {{- include "private-assistant.labels" .context | nindent 4 }}
  {{- with .config.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if and .config.className (semverCompare ">=1.18-0" .context.Capabilities.KubeVersion.GitVersion) }}
  ingressClassName: {{ .config.className }}
  {{- end }}
  {{- if .config.tls }}
  tls:
    {{- range .config.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      {{- if .secretName }}
      secretName: {{ .secretName }}
      {{- end }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .config.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            {{- if and .pathType (semverCompare ">=1.18-0" $.context.Capabilities.KubeVersion.GitVersion) }}
            pathType: {{ .pathType }}
            {{- end }}
            backend:
              {{- if semverCompare ">=1.19-0" $.context.Capabilities.KubeVersion.GitVersion }}
              service:
                name: {{ $fullName }}-{{ $.serviceName }}
                port:
                  name: http
              {{- else }}
              serviceName: {{ $fullName }}-{{ $.serviceName }}
              servicePort: 80
              {{- end }}
          {{- end }}
    {{- end }}
{{- end -}}

{{/*
Common deployment metadata
*/}}
{{- define "private-assistant.deployment.metadata" -}}
metadata:
  name: {{ include "private-assistant.fullname" .context }}-{{ .component }}
  labels:
    {{- include "private-assistant.labels" .context | nindent 4 }}
spec:
  replicas: {{ .replicas }}
  revisionHistoryLimit: 0
  selector:
    matchLabels:
      {{- if .hasComponentLabel }}
      app.kubernetes.io/component: {{ .component }}
      {{- end }}
      {{- include "private-assistant.selectorLabels" .context | nindent 6 }}
{{- end -}}

{{/*
Common deployment pod template metadata
*/}}
{{- define "private-assistant.deployment.podMetadata" }}
  template:
    metadata:
      {{- with .context.Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- if .hasComponentLabel }}
        app.kubernetes.io/component: {{ .component }}
        {{- end }}
        {{- include "private-assistant.labels" .context | nindent 8 }}
	{{- with .context.Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- if .imagePullSecret }}
      imagePullSecrets:
        - name: {{ .imagePullSecret }}
      {{- end }}
      serviceAccountName: {{ include "private-assistant.serviceAccountName" .context }}
      securityContext:
        {{- toYaml .context.Values.podSecurityContext | nindent 8 }}
{{- end }}

{{/*
Common HTTP probes configuration
*/}}
{{- define "private-assistant.deployment.httpProbes" -}}
livenessProbe:
  httpGet:
    port: http
    path: /health
  initialDelaySeconds: 5
  failureThreshold: 3
  periodSeconds: 60
readinessProbe:
  httpGet:
    port: http
    path: /health
  initialDelaySeconds: 5
  failureThreshold: 3
  periodSeconds: 15
startupProbe:
  tcpSocket:
    port: http
  failureThreshold: 30
  periodSeconds: 5
{{- end -}}

{{/*
Get Mosquitto/MQTT broker host
*/}}
{{- define "private-assistant.mosquitto.host" -}}
{{- if .Values.mosquitto.serviceHost -}}
{{ .Values.mosquitto.serviceHost }}
{{- else -}}
{{ .Release.Name }}-mosquitto.{{ include "private-assistant.namespace" . }}.svc{{ if ne .Values.clusterDomain "" }}.{{ .Values.clusterDomain }}{{ end }}
{{- end -}}
{{- end -}}

{{/*
Get Mosquitto/MQTT broker port
*/}}
{{- define "private-assistant.mosquitto.port" -}}
{{- if .Values.mosquitto.servicePort -}}
{{ .Values.mosquitto.servicePort }}
{{- else -}}
1883
{{- end -}}
{{- end -}}

{{/*
Generate backend service URL for frontend proxy
*/}}
{{- define "private-assistant.webui.backendUrl" -}}
http://{{ include "private-assistant.fullname" . }}-webui-backend.{{ include "private-assistant.namespace" . }}.svc{{ if ne .Values.clusterDomain "" }}.{{ .Values.clusterDomain }}{{ end }}:8080
{{- end -}}

{{/*
Generate PostgreSQL environment variables
Usage: include "private-assistant.postgres.env" (dict "component" "webUiBackend" "componentConfig" .Values.webUiBackend.config.postgres "context" .)
Parameters:
  - component: Component name (for debugging/comments)
  - componentConfig: Component-specific postgres config (optional)
  - context: The root context (.)
This helper checks:
  1. If component has specific postgres config, use it
  2. Otherwise, use global postgres config
  3. Support both existingSecret and direct values
*/}}
{{- define "private-assistant.postgres.env" -}}
{{- $component := .component -}}
{{- $context := .context -}}
{{- $componentConfig := .componentConfig -}}
{{- $useGlobal := true -}}
{{- if $componentConfig -}}
  {{- if or $componentConfig.server $componentConfig.host -}}
    {{- $useGlobal = false -}}
  {{- end -}}
{{- end -}}
{{- if $useGlobal -}}
  {{- if $context.Values.postgres.existingSecret.enabled -}}
# PostgreSQL from global existingSecret ({{ $context.Values.postgres.existingSecret.name }})
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: {{ $context.Values.postgres.existingSecret.name }}
      key: {{ $context.Values.postgres.existingSecret.keys.username }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ $context.Values.postgres.existingSecret.name }}
      key: {{ $context.Values.postgres.existingSecret.keys.password }}
- name: POSTGRES_HOST
  valueFrom:
    secretKeyRef:
      name: {{ $context.Values.postgres.existingSecret.name }}
      key: {{ $context.Values.postgres.existingSecret.keys.host }}
- name: POSTGRES_PORT
  valueFrom:
    secretKeyRef:
      name: {{ $context.Values.postgres.existingSecret.name }}
      key: {{ $context.Values.postgres.existingSecret.keys.port }}
- name: POSTGRES_DB
  valueFrom:
    secretKeyRef:
      name: {{ $context.Values.postgres.existingSecret.name }}
      key: {{ $context.Values.postgres.existingSecret.keys.dbname }}
  {{- else -}}
# PostgreSQL from global direct values
- name: POSTGRES_HOST
  value: {{ $context.Values.postgres.server | quote }}
- name: POSTGRES_PORT
  value: {{ $context.Values.postgres.port | quote }}
- name: POSTGRES_DB
  value: {{ $context.Values.postgres.db | quote }}
- name: POSTGRES_USER
  value: {{ $context.Values.postgres.user | quote }}
- name: POSTGRES_PASSWORD
  value: {{ $context.Values.postgres.password | quote }}
  {{- end -}}
{{- else -}}
# PostgreSQL from component-specific config
- name: POSTGRES_HOST
  value: {{ $componentConfig.server | default $componentConfig.host | quote }}
- name: POSTGRES_PORT
  value: {{ $componentConfig.port | quote }}
- name: POSTGRES_DB
  value: {{ $componentConfig.db | default $componentConfig.database | quote }}
- name: POSTGRES_USER
  value: {{ $componentConfig.user | quote }}
- name: POSTGRES_PASSWORD
  value: {{ $componentConfig.password | quote }}
{{- end -}}
{{- end -}}

{{/*
MQTT environment variables helper
Usage: include "private-assistant.mqtt.env" (dict "component" "webUiBackend" "componentConfig" .Values.webUiBackend.config.mqtt "context" .)
Parameters:
  - component: Component name for logging/debugging
  - componentConfig: Component-specific MQTT config (optional, nil to use global)
  - context: Root context ($)
*/}}
{{- define "private-assistant.mqtt.env" -}}
{{- $context := .context -}}
{{- $componentConfig := .componentConfig -}}
{{- $useGlobal := true -}}
{{- if $componentConfig -}}
  {{- if or $componentConfig.username $componentConfig.host -}}
    {{- $useGlobal = false -}}
  {{- end -}}
{{- end -}}
{{- if $useGlobal -}}
# MQTT from global mosquitto values
- name: MQTT_HOST
  value: {{ include "private-assistant.mosquitto.host" $context | quote }}
- name: MQTT_PORT
  value: {{ include "private-assistant.mosquitto.port" $context | quote }}
{{- if $context.Values.mosquitto.username }}
- name: MQTT_USERNAME
  value: {{ $context.Values.mosquitto.username | quote }}
{{- end }}
{{- if $context.Values.mosquitto.password }}
- name: MQTT_PASSWORD
  value: {{ $context.Values.mosquitto.password | quote }}
{{- end }}
{{- else -}}
# MQTT from component-specific config
- name: MQTT_HOST
  value: {{ $componentConfig.host | quote }}
- name: MQTT_PORT
  value: {{ $componentConfig.port | quote }}
{{- if $componentConfig.username }}
- name: MQTT_USERNAME
  value: {{ $componentConfig.username | quote }}
{{- end }}
{{- if $componentConfig.password }}
- name: MQTT_PASSWORD
  value: {{ $componentConfig.password | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Derive frontend URL from ingress configuration
Returns: https://app.example.com or http://app.example.com
*/}}
{{- define "private-assistant.webui.frontendUrl" -}}
{{- $ingress := .Values.webUi.frontend.ingress -}}
{{- if and $ingress.enabled $ingress.hosts -}}
  {{- $firstHost := index $ingress.hosts 0 -}}
  {{- $protocol := "http" -}}
  {{- if $ingress.tls -}}
    {{- range $ingress.tls -}}
      {{- if has $firstHost.host .hosts -}}
        {{- $protocol = "https" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s://%s" $protocol $firstHost.host -}}
{{- else -}}
  http://private-assistant.local
{{- end -}}
{{- end -}}

{{/*
Derive backend API base URL for frontend (VITE_API_URL)
Returns just the base URL (protocol + host) - frontend handles the path
Priority: backend ingress > internal service
*/}}
{{- define "private-assistant.webui.backendApiUrl" -}}
{{- $backendIngress := .Values.webUi.backend.ingress -}}
{{- if and $backendIngress.enabled $backendIngress.hosts -}}
  {{- $firstHost := index $backendIngress.hosts 0 -}}
  {{- $protocol := "http" -}}
  {{- if $backendIngress.tls -}}
    {{- range $backendIngress.tls -}}
      {{- if has $firstHost.host .hosts -}}
        {{- $protocol = "https" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s://%s" $protocol $firstHost.host -}}
{{- else -}}
  {{- include "private-assistant.webui.backendUrl" . -}}
{{- end -}}
{{- end -}}

{{/*
Generate CORS origins from frontend ingress hosts
Returns: comma-separated list like "https://app.example.com,http://dev.example.com"
*/}}
{{- define "private-assistant.webui.corsOrigins" -}}
{{- $ingress := .Values.webUi.frontend.ingress -}}
{{- $origins := list -}}
{{- if and $ingress.enabled $ingress.hosts -}}
  {{- range $ingress.hosts -}}
    {{- $protocol := "http" -}}
    {{- if $ingress.tls -}}
      {{- range $ingress.tls -}}
        {{- if has $.host .hosts -}}
          {{- $protocol = "https" -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $origins = append $origins (printf "%s://%s" $protocol .host) -}}
  {{- end -}}
{{- end -}}
{{- if not $origins -}}
  http://localhost:3000,http://localhost:5173
{{- else -}}
  {{- join "," $origins -}}
{{- end -}}
{{- end -}}

{{/*
Auto-generate first superuser email from ingress host
Returns: admin@{frontend-host} or provided value
*/}}
{{- define "private-assistant.webui.firstSuperuser" -}}
{{- if .Values.webUi.backend.firstSuperuser -}}
  {{- .Values.webUi.backend.firstSuperuser -}}
{{- else -}}
  {{- $ingress := .Values.webUi.frontend.ingress -}}
  {{- if and $ingress.enabled $ingress.hosts -}}
    {{- $firstHost := index $ingress.hosts 0 -}}
    {{- printf "admin@%s" $firstHost.host -}}
  {{- else -}}
    admin@private-assistant.local
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate or lookup secret key for Web UI backend
*/}}
{{- define "private-assistant.webui.secretKey" -}}
{{- $secretName := printf "%s-webui-backend" (include "private-assistant.fullname" .) -}}
{{- $existingSecret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if $existingSecret -}}
  {{- index $existingSecret.data "secret-key" | b64dec -}}
{{- else -}}
  {{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{/*
Generate or lookup first superuser password
*/}}
{{- define "private-assistant.webui.firstSuperuserPassword" -}}
{{- $secretName := printf "%s-webui-backend" (include "private-assistant.fullname" .) -}}
{{- $existingSecret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if $existingSecret -}}
  {{- index $existingSecret.data "first-superuser-password" | b64dec -}}
{{- else -}}
  {{- randAlphaNum 40 -}}
{{- end -}}
{{- end -}}
