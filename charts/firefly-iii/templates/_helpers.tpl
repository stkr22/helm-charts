{{/*
Expand the name of the chart.
*/}}
{{- define "fireflyiii.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fireflyiii.fullname" -}}
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
{{- define "fireflyiii.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "fireflyiii.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "fireflyiii.labels" -}}
helm.sh/chart: {{ include "fireflyiii.chart" . }}
{{ include "fireflyiii.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fireflyiii.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fireflyiii.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fireflyiii.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fireflyiii.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "fireflyiii.frontend.appKey" -}}
{{- $secret := (lookup "v1" "Secret" (include "fireflyiii.namespace" .) (include "fireflyiii.fullname" . | cat "-frontend") ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "appKey" -}}
  {{- else -}}
    {{- (randAlphaNum 32) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "fireflyiii.frontend.cronToken" -}}
{{- $secret := (lookup "v1" "Secret" (include "fireflyiii.namespace" .) (include "fireflyiii.fullname" . | cat "-frontend")) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "cronToken" -}}
  {{- else -}}
    {{- (randAlphaNum 32) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "fireflyiii.postgres.password" -}}
{{- $secret := (lookup "v1" "Secret" (include "fireflyiii.namespace" .) (include "fireflyiii.fullname" . | cat "-db") ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "postgresql-password" -}}
  {{- else -}}
    {{- (randAlphaNum 40) | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Defines default user.
*/}}
{{- define "fireflyiii.postgres.user" -}}
{{- "firefly" | b64enc | quote -}}
{{- end -}}


{{/*
Looks if there's an existing secret and reuse its password. If not it generates
new password and use it.
*/}}
{{- define "fireflyiii.importer.accessToken" -}}
{{- $secret := (lookup "v1" "Secret" (include "fireflyiii.namespace" .) (include "fireflyiii.fullname" . | cat "-importer") ) -}}
  {{- if $secret -}}
    {{-  index $secret "data" "accessToken" -}}
  {{- else if .Values.importer.accessToken -}}
    {{- .Values.importer.accessToken -}}
  {{- else -}}
    {{- (randAlphaNum 32) | b64enc | quote -}}
  {{- end -}}
{{- end -}}
