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

{{- define "private-assistant.config" -}}
mqtt_server_host: {{ .Values.mosquitto.serviceHost }}
mqtt_server_port: {{ .Values.mosquitto.servicePort }}
{{- end -}}

{{- define "private-assistant.groundStationConfig" -}}
speech_synthesis_api: {{ if .Values.groundStation.ttsServiceHostOverwrite }}{{ .Values.groundStation.ttsServiceHostOverwrite }}{{ else }}http://{{ .Release.Name }}-tts-engine.{{ .Release.Namespace }}.svc{{ if ne .Values.clusterDomain "" }}.{{ .Values.clusterDomain }}/synthesizeSpeech{{ end }}{{ end }}
speech_synthesis_api_token: {{ if .Values.groundStation.ttsServiceTokenOverwrite }}{{ .Values.groundStation.ttsServiceTokenOverwrite }}{{ else }}{{ .Values.ttsEngine.config.allowedUserToken }}{{ end }}
{{- end -}}

{{- define "private-assistant.config.base64" -}}
{{ include "private-assistant.config" . | b64enc }}
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
