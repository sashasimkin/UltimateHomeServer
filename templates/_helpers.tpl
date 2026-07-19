{{- define "ultimatehomeserver.persistence.claimName" -}}
{{- $service := . -}}
{{- if and $service.persistence $service.persistence.use -}}
{{- required "services.<service>.persistence.claimName is required when persistence.use is true" $service.persistence.claimName -}}
{{- else -}}
longhorn-volv-pvc
{{- end -}}
{{- end -}}
