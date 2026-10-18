{{- define "ultimatehomeserver.persistence.claimName" -}}
{{- $service := . -}}
{{- if and $service.persistence $service.persistence.use -}}
{{- required "services.<service>.persistence.claimName is required when persistence.use is true" $service.persistence.claimName -}}
{{- else -}}
longhorn-volv-pvc
{{- end -}}
{{- end -}}

{{- define "ultimatehomeserver.monobank.webhookSecretName" -}}
{{- $managed := .managedWebhookSecret | default dict -}}
{{- $prefix := $managed.namePrefix | default "monobank-firefly3-bot-webhook" -}}
{{- $version := required "managedWebhookSecret.version is required" $managed.version | toString -}}
{{- $name := printf "%s-%s" $prefix $version -}}
{{- if or (gt (len $name) 63) (not (regexMatch "^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" $name)) -}}
{{- fail "managedWebhookSecret namePrefix-version must be a DNS label of at most 63 characters" -}}
{{- end -}}
{{- $name -}}
{{- end -}}
