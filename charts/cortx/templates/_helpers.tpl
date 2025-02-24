{{/*
Expand the name of the chart.
*/}}
{{- define "cortx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cortx.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cortx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cortx.labels" -}}
helm.sh/chart: {{ include "cortx.chart" . }}
{{ include "cortx.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cortx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cortx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cortx.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cortx.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the CORTX configuration configmap
*/}}
{{- define "cortx.configmapName" -}}
{{- include "cortx.fullname" . -}}
{{- end -}}

{{/*
Return the CORTX SSL certificate configmap
*/}}
{{- define "cortx.tls.configmapName" -}}
{{- printf "%s-ssl-cert" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Return the name of the CORTX secret
*/}}
{{- define "cortx.secretName" -}}
{{- $secret := tpl .Values.existingSecret . -}}
{{- required "A name of a Secret containing the CORTX configuration secrets is required" $secret -}}
{{- end -}}

{{/*
Return the name of the Control component
*/}}
{{- define "cortx.control.fullname" -}}
{{- printf "%s-control" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Return the Control Agent endpoint port
*/}}
{{- define "cortx.control.agentPort" -}}
23256
{{- end -}}

{{/*
Return the name of the HA component
*/}}
{{- define "cortx.ha.fullname" -}}
{{- printf "%s-ha" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Return the name of the Hare hax component
*/}}
{{- define "cortx.hare.hax.fullname" -}}
{{- printf "%s-hax" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Create a URL for the Hare hax HTTP endpoint
*/}}
{{- define "cortx.hare.hax.url" -}}
{{- printf "%s://%s:%d" .Values.hare.hax.ports.http.protocol (include "cortx.hare.hax.fullname" $) (int .Values.hare.hax.ports.http.port) -}}
{{- end -}}

{{/*
Return the Hare hax TCP endpoint port
*/}}
{{- define "cortx.hare.hax.tcpPort" -}}
22001
{{- end -}}

{{/*
Return the name of the Server component
*/}}
{{- define "cortx.server.fullname" -}}
{{- printf "%s-server" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Return the name of the Server service domain
*/}}
{{- define "cortx.server.serviceDomain" -}}
{{- printf "%s-headless.%s.svc.%s" (include "cortx.server.fullname" .) .Release.Namespace .Values.clusterDomain -}}
{{- end -}}

{{/*
Return the RGW HTTP endpoint port
*/}}
{{- define "cortx.server.rgwHttpPort" -}}
22751
{{- end -}}

{{/*
Return the RGW HTTPS endpoint port
*/}}
{{- define "cortx.server.rgwHttpsPort" -}}
23001
{{- end -}}

{{/*
Return the RGW-Motr-client endpoint port
*/}}
{{- define "cortx.server.motrClientPort" -}}
22501
{{- end -}}

{{/*
Return the name of the Data component
*/}}
{{- define "cortx.data.fullname" -}}
{{- printf "%s-data" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Return the name of the Data service domain
*/}}
{{- define "cortx.data.serviceDomain" -}}
{{- printf "%s-headless.%s.svc.%s" (include "cortx.data.fullname" .) .Release.Namespace .Values.clusterDomain -}}
{{- end -}}

{{/*
Return the Motr IOS endpoint port
*/}}
{{- define "cortx.data.iosPort" -}}
21002
{{- end -}}

{{/*
Return the Motr confd endpoint port
*/}}
{{- define "cortx.data.confdPort" -}}
21001
{{- end -}}

{{/*
Return the number of StatefulSets required to fullfil the containerGroupSize to CVG mapping defined by the user
This is calculated by (Number of CVGs in storage set) / (storage set containerGroupSize).
If CVGs are defined, the minimum value this should return is 1.
If CVGs are not defined, this should return 0.
*/}}
{{- define "cortx.data.statefulSetCount" -}}
{{/* Currently a maximum of one storage set is supported */}}
{{- if gt (len .Values.storageSets) 1 -}}
{{- fail "A maximum of one storage set is currently supported" -}}
{{- end -}}
{{- $cvgCount := 0 -}}
{{- $storageSet := first .Values.storageSets -}}
{{- if and $storageSet.storage ($storageSet.containerGroupSize | int) -}}
  {{- $cvgCount = len ($storageSet.storage | chunk ($storageSet.containerGroupSize | int)) -}}
{{- end -}}
{{- printf "%d" $cvgCount -}}
{{- end -}}

{{/*
Returns the string used to group CORTX Data StatefulSets.
NOTE: Until CORTX-32368 is resolved, this needs to be a single character due to FQDN length issues.
*/}}
{{- define "cortx.data.groupPrefix" -}}
g
{{- end -}}

{{/*
Returns the fullname of the CORTX Data StatefulSet with group suffix.
Must be called with input scope of a Dictionary with the following keys and values:
- .root = $
- .stsIndex = Iterator index of all CORTX Data StatefulSets
*/}}
{{- define "cortx.data.groupFullname" -}}
{{- printf "%s-%s%d" (include "cortx.data.fullname" .root) (include "cortx.data.groupPrefix" .) .stsIndex -}}
{{- end -}}

{{/*
Returns the fully-formatted CORTX node type for a given node that qualifies as a "data node".
Must be called with input scope of set to the appropriate StatefulSet index.
*/}}
{{- define "cortx.data.dataNodeName" -}}
{{- printf "%s/%d" (include "cortx.data.dataNodePrefix" .) (. | int) -}}
{{- end -}}

{{/*
Returns the fully-formatted CORTX node type for a given node that qualifies as a "data node" for use as a Kubernetes Label.
See also https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set
Must be called with input scope of set to the appropriate StatefulSet index.
*/}}
{{- define "cortx.data.dataNodeLabel" -}}
{{- printf "%s-%d" (include "cortx.data.dataNodePrefix" .) (. | int) -}}
{{- end -}}

{{/*
Returns the prefix for CORTX node types that qualify as "data nodes".
*/}}
{{- define "cortx.data.dataNodePrefix" -}}
data_node
{{- end -}}

{{/*
Return the name of the Client component
*/}}
{{- define "cortx.client.fullname" -}}
{{- printf "%s-client" (include "cortx.fullname" .) -}}
{{- end -}}

{{/*
Return the name of the Client service domain
*/}}
{{- define "cortx.client.serviceDomain" -}}
{{- printf "%s-headless.%s.svc.%s" (include "cortx.client.fullname" .) .Release.Namespace .Values.clusterDomain -}}
{{- end -}}

{{/*
Return the Motr-client endpoint port
*/}}
{{- define "cortx.client.motrClientPort" -}}
21501
{{- end -}}

{{/*
Return the setup container log details setting for the component. The component value overrides the global value.
{{ include "cortx.setupLoggingDetail" ( dict "component" .Values.path.to.the.component "root" $) }}
*/}}
{{- define "cortx.setupLoggingDetail" -}}
{{- coalesce .component.setupLoggingDetail .root.Values.global.cortx.setupLoggingDetail -}}
{{- end -}}

{{/*
Create a CORTX Confstore URL
*/}}
{{- define "cortx.confstore.url" -}}
{{- if .Values.consul.enabled -}}
{{- printf "consul://%s-consul-server:8500/conf" (include "cortx.fullname" .) -}}
{{- else -}}
{{/* TODO: handle external Consul services */}}
{{- printf "yaml:///etc/cortx/cluster.conf" -}}
{{- end -}}
{{- end -}}
