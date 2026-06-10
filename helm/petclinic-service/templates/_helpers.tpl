{{/*
Resource name — always the Helm release name.
*/}}
{{- define "petclinic-service.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Full image reference built from global registry + env name + per-service image name + tag.
*/}}
{{- define "petclinic-service.image" -}}
{{ .Values.global.imageRegistry }}/petclinic-{{ .Values.global.envName }}/{{ .Values.image.name }}:{{ .Values.image.tag }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "petclinic-service.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "petclinic-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: petclinic
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/component: {{ .Values.component }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
{{- end }}

{{/*
Selector labels — stable subset used in matchLabels and Service selector.
*/}}
{{- define "petclinic-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "petclinic-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
