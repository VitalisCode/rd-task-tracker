{{- define "rd-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version -}}
{{- end -}}

{{- define "rd-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rd-api.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "rd-api.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "rd-api.labels" -}}
helm.sh/chart: {{ include "rd-api.chart" . }}
app.kubernetes.io/name: {{ include "rd-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "rd-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rd-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
