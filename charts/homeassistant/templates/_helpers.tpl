{{/*
Expand the name of the chart.
*/}}
{{- define "homeassistant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "homeassistant.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "homeassistant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "homeassistant.labels" -}}
helm.sh/chart: {{ include "homeassistant.chart" . }}
{{ include "homeassistant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "homeassistant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homeassistant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels postgres
*/}}
{{- define "homeassistant.postgres.labels" -}}
helm.sh/chart: {{ include "homeassistant.chart" . }}
{{ include "homeassistant.postgres.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels postgres
*/}}
{{- define "homeassistant.postgres.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homeassistant.name" . }}-db
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "fullstack.postgres.password" -}}
{{- $secret := (lookup "v1" "Secret" (include "fullstack.namespace" .) (include "fullstack.fullname" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "postgresql-password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Defines default user.
*/}}
{{- define "fullstack.postgres.user" -}}
{{- "backend" | b64enc | quote -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "homeassistant.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "homeassistant.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
