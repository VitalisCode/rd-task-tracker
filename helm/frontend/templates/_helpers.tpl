{{- define "rd-frontend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version -}}
{{- end -}}

{{- define "rd-frontend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rd-frontend.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "rd-frontend.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "rd-frontend.labels" -}}
helm.sh/chart: {{ include "rd-frontend.chart" . }}
app.kubernetes.io/name: {{ include "rd-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "rd-frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rd-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
