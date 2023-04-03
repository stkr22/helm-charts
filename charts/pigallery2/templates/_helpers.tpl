{{/*
Expand the name of the chart.
*/}}
{{- define "pigallery2.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pigallery2.fullname" -}}
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
{{- define "pigallery2.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pigallery2.labels" -}}
helm.sh/chart: {{ include "pigallery2.chart" . }}
{{ include "pigallery2.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pigallery2.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pigallery2.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels db
*/}}
{{- define "pigallery2.db.labels" -}}
helm.sh/chart: {{ include "pigallery2.chart" . }}
{{ include "pigallery2.db.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels db
*/}}
{{- define "pigallery2.db.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pigallery2.name" . }}-db
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pigallery2.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pigallery2.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "pigallery2.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "pigallery2.db.password" -}}
{{- $secret := (lookup "v1" "Secret" (include "pigallery2.namespace" .) (include "pigallery2.fullname" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "mysql-password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{- define "pigallery2.db.rootPassword" -}}
{{- $secret := (lookup "v1" "Secret" (include "pigallery2.namespace" .) (include "pigallery2.fullname" .) ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "mysql-root-password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Defines default user.
*/}}
{{- define "pigallery2.db.user" -}}
{{- "pigallery" | b64enc | quote -}}
{{- end -}}
