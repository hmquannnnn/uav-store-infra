{{/*
Namespace của toàn bộ release.
Dùng: {{ include "uav-store.namespace" . }}
*/}}
{{- define "uav-store.namespace" -}}
{{- .Release.Namespace | default "uav-store" }}
{{- end }}

{{/*
Labels chuẩn Helm cho mọi resource trong umbrella chart.
Dùng: {{ include "uav-store.labels" . }}
*/}}
{{- define "uav-store.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
