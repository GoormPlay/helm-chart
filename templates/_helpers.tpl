{{/*
Expand the name of the chart (nameOverride 우선)
*/}}
{{- define "base-template.name" -}}
{{- default .Values.nameOverride .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name (fullnameOverride 우선)
*/}}
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
{{- define "base-template.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.fullnameOverride }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ .Values.nameOverride }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  selector:
    app: {{ .Values.nameOverride }}
{{- end }}
