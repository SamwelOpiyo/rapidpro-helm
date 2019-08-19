{{/* vim: set filetype=mustache: */}}
{{/*
  Expand the name of the chart.
*/}}
{{- define "rapidpro.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  Create a default fully qualified app name.
  We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
  If release name contains chart name it will be used as a full name.
*/}}
{{- define "rapidpro.fullname" -}}
  {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
  Create chart name and version as used by the chart label.
*/}}
{{- define "rapidpro.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
  Set elasticsearch service host.
*/}}
{{- define "elasticsearch.service_host" -}}
  {{- if .Values.elasticsearch.enabled -}}
    {{- .Release.Name }}-elasticsearch-client.{{ .Release.Namespace }}.svc.cluster.local
  {{- end -}}
{{- end -}}


{{/*
Set redis master service host.
*/}}
{{- define "redis.master_service_host" -}}
  {{- if .Values.redis.enabled -}}
    {{- .Release.Name }}-redis-master.{{ .Release.Namespace }}.svc.cluster.local
  {{- end -}}
{{- end -}}


{{/*
Set redis slave service host.
*/}}
{{- define "redis.slave_service_host" -}}
  {{- if .Values.elasticsearch.enabled -}}
    {{- .Release.Name }}-redis-slave.{{ .Release.Namespace }}.svc.cluster.local
  {{- end -}}
{{- end -}}


{{/*
Set patroni service host.
*/}}
{{- define "patroni.service_host" -}}
  {{- if .Values.patroni.enabled -}}
    {{- .Release.Name }}-patroni.{{ .Release.Namespace }}.svc.cluster.local
  {{- end -}}
{{- end -}}


{{/*
  Set environment variables that will enable rapidpro use installed dependencies.
*/}}
{{- define "rapidpro.dependency_envs" }}
  - name: SECRET_KEY
    value: "{{ default (randAlphaNum 20) .Values.rapidpro.env.SECRET_KEY }}"
  {{- if and .Values.rapidpro.ingress.enabled }}
    {{- range $index, $host := .Values.rapidpro.ingress.hosts -}}
      {{- if and $host.host (eq $index 0) }}
  - name: TEMBA_HOST
    value: {{ $host.host }}
  - name: DOMAIN_NAME
    value: {{ $host.host }}
      {{- end -}}
    {{ end }}
  - name: ALLOWED_HOSTS
    value: "{{ range $host := .Values.rapidpro.ingress.hosts }}{{ $host.host }};{{ end }}"
  {{- end }}
  {{- if include "elasticsearch.service_host" . }}
  - name: ELASTICSEARCH_URL
    value: "http://{{ include "elasticsearch.service_host" . }}:9200"
  {{- end }}
  {{- if include "redis.master_service_host" . }}
  - name: BROKER_URL
    value: "redis://{{ include "redis.master_service_host" . }}:6379/0"
  {{- end }}
  {{- if include "redis.master_service_host" . }}
  - name: CELERY_RESULT_BACKEND
    value: "redis://{{ include "redis.master_service_host" . }}:6379/0"
  {{- end }}
  {{- if include "redis.master_service_host" . }}
  - name: REDIS_URL
    value: "redis://{{ include "redis.master_service_host" . }}:6379/0,redis://{{ include "redis.slave_service_host" . }}:6379/0"
  {{- end -}}
{{- end -}}
