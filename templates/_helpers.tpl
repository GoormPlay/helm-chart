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

{{- define "base-template.labels" -}}
app.kubernetes.io/name: {{ include "base-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "base-template.selectorLabels" -}}
app: {{ include "base-template.name" . }}
{{- end }}

# 👇 Context 변환 헬퍼
{{- define "base-template.ctx" -}}
{{- if .Values.base-template }}
{{- .Values.base-template | toYaml | fromYaml }}
{{- else }}
{{- .Values | toYaml | fromYaml }}
{{- end }}
{{- end }}
