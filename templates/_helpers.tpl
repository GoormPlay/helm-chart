{{/* base-template: configmap */}}
{{- define "base-template.configmap" }}
{{- if .Values.env.useConfigMap }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.fullnameOverride }}-config
  namespace: {{ .Release.Namespace }}
data:
  SPRING_PROFILES_ACTIVE: "prod"
  S3_FRONTEND_ORIGIN: "https://front.aws-test-site.shop"
  KAFKA_BOOTSTRAP_SERVERS: "15.164.236.86:9092,3.35.5.47:9092,43.203.112.201:9092"
  KAFKA_SCHEMA_REGISTRY_SERVER: "15.164.236.86:8081"
{{- end }}
{{- end }}
{{/* base-template: service */}}
{{- define "base-template.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.fullnameOverride }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Values.nameOverride }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  selector:
    app: {{ .Values.nameOverride }}
{{- end }}

{{/* base-template: preview-service */}}
{{- define "base-template.preview-service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.fullnameOverride }}-preview
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Values.nameOverride }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  selector:
    app: {{ .Values.nameOverride }}
{{- end }}


{{/* base-template: deployment */}}
{{- define "base-template.deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.fullnameOverride }}
  namespace: {{ .Release.Namespace }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.nameOverride }}
  template:
    metadata:
      labels:
        app: {{ .Values.nameOverride }}
    spec:
      {{- with .Values.nodeSelector }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Values.fullnameOverride }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
          envFrom:
            {{- if .Values.env.useConfigMap }}
            - configMapRef:
                name: {{ .Values.fullnameOverride }}-config
            {{- end }}
            {{- if .Values.env.useSecret }}
            - secretRef:
                name: {{ .Values.fullnameOverride }}-secret
            {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
{{- end }}

{{/* base-template: external-secret */}}
{{- define "base-template.external-secret" }}
{{- if .Values.externalSecret.enabled }}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ .Values.fullnameOverride }}
  namespace: {{ .Release.Namespace }}
spec:
  refreshInterval: {{ .Values.externalSecret.refreshInterval }}
  secretStoreRef:
    kind: {{ .Values.externalSecret.secretStore.kind }}
    name: {{ .Values.externalSecret.secretStore.name }}
  target:
    name: {{ .Values.fullnameOverride }}-secret
  dataFrom:
    - extract:
        key: {{ .Values.externalSecret.dataFromKey }}
{{- end }}
{{- end }}

{{/* base-template: hpa */}}
{{- define "base-template.hpa" }}
{{- if .Values.hpa.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.fullnameOverride }}-hpa
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Values.nameOverride }}
spec:
  scaleTargetRef:
    {{- if .Values.rollouts.enabled }}
    apiVersion: argoproj.io/v1alpha1
    kind: Rollout
    {{- else }}
    apiVersion: apps/v1
    kind: Deployment
    {{- end }}
    name: {{ .Values.fullnameOverride }}
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.hpa.targetCPUUtilizationPercentage }}
{{- end }}
{{- end }}

{{/* base-template: ingress */}}
{{- define "base-template.ingress" }}
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.fullnameOverride }}-ingress
  namespace: {{ .Release.Namespace }}
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: my-apps
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=60
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-2:557690584596:certificate/e491f298-1ecc-4586-95d9-47e288a350ac
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/subnets: subnet-0903460f869caf2a1,subnet-00c246ce288c3cbf8
spec:
  ingressClassName: alb
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.fullnameOverride }}
                port:
                  number: {{ .Values.service.port }}
{{- end }}
{{- end }}
{{/* base-template: rollout */}}
{{- define "base-template.rollout" }}
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ .Values.fullnameOverride }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Values.nameOverride }}
spec:
  replicas: {{ .Values.replicaCount }}
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: {{ .Values.nameOverride }}
  template:
    metadata:
      labels:
        app: {{ .Values.nameOverride }}
    spec:
      {{- with .Values.nodeSelector }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Values.fullnameOverride }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
          ports:
            - containerPort: {{ .Values.service.targetPort }}
          envFrom:
            {{- if .Values.env.useConfigMap }}
            - configMapRef:
                name: {{ .Values.fullnameOverride }}-config
            {{- end }}
            {{- if .Values.env.useSecret }}
            - secretRef:
                name: {{ .Values.fullnameOverride }}-secret
            {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
  strategy:
    blueGreen:
      activeService: {{ .Values.fullnameOverride }}
      previewService: {{ .Values.fullnameOverride }}-preview
      autoPromotionEnabled: {{ .Values.rollouts.autoPromotionEnabled | default false }}
      scaleDownDelaySeconds: {{ .Values.rollouts.blueGreen.scaleDownDelaySeconds | default 300 }}
      {{- if .Values.rollouts.analysis }}
      prePromotionAnalysis:
        templates:
          {{- with .Values.rollouts.analysis.templates }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        args:
          - name: service-name
            value: {{ .Values.fullnameOverride }}
          {{- with .Values.rollouts.analysis.additionalArgs }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
      {{- end }}
{{- end }}