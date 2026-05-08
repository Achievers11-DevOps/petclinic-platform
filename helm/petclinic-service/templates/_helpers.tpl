{{- define "petclinic-service.name" -}}
{{- .Release.Name }}
{{- end }}

{{- define "petclinic-service.labels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/part-of: petclinic
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "petclinic-service.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
