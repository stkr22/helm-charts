{{/*
Expand the name of the chart.
*/}}
{{- define "fullstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fullstack.fullname" -}}
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
{{- define "fullstack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels backend
*/}}
{{- define "fullstack.backend.labels" -}}
helm.sh/chart: {{ include "fullstack.chart" . }}
{{ include "fullstack.backend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels frontend
*/}}
{{- define "fullstack.frontend.labels" -}}
helm.sh/chart: {{ include "fullstack.chart" . }}
{{ include "fullstack.frontend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels frontend
*/}}
{{- define "fullstack.frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullstack.name" . }}-frontend
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Selector labels backend
*/}}
{{- define "fullstack.backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullstack.name" . }}-backend
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels postgres
*/}}
{{- define "fullstack.postgres.labels" -}}
helm.sh/chart: {{ include "fullstack.chart" . }}
{{ include "fullstack.postgres.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels postgres
*/}}
{{- define "fullstack.postgres.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fullstack.name" . }}-db
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fullstack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fullstack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
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
backend
{{- end -}}
