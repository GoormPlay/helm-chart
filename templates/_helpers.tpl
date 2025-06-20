{{- define "base-template.name" -}}
{{- default .Values.nameOverride .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "base-template.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "base-template.name" . }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "base-template.labels" -}}
app.kubernetes.io/name: {{ include "base-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "base-template.selectorLabels" -}}
app: {{ include "base-template.name" . }}
{{- end }}
