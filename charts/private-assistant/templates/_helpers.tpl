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

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "private-assistant.postgres.postgres-password" -}}
{{- $secret := (lookup "v1" "Secret" (include "private-assistant.namespace" .) "private-assistant-postgres-credentials" ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "postgres-password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "private-assistant.postgres.password" -}}
{{- $secret := (lookup "v1" "Secret" (include "private-assistant.namespace" .) "private-assistant-postgres-credentials" ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{- define "private-assistant.config" -}}
mqtt_server_host: {{ if .Values.mosquitto.serviceHostOverwrite }}{{ .Values.mosquitto.serviceHostOverwrite }}{{ else }}{{ .Release.Name }}-mosquitto-service.{{ .Release.Namespace }}.svc{{ if ne .Values.clusterDomain "" }}.{{ .Values.clusterDomain }}{{ end }}{{ end }}
mqtt_server_port: {{ if .Values.mosquitto.servicePortOverwrite }}{{ .Values.mosquitto.servicePortOverwrite }}{{ else }}{{ .Values.mosquitto.service.ports.mqtt.port }}{{ end }}
{{- end -}}

{{- define "private-assistant.config.base64" -}}
{{ include "private-assistant.config" . | b64enc }}
{{- end -}}
