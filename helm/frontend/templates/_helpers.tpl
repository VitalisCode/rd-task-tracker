{{- define "rd-frontend.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "rd-frontend.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "rd-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "rd-frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rd-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}