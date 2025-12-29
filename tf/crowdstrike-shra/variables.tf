variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "region" {
  description = "AWS region for the EKS cluster."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the SHRA deployment."
  type        = string
  default     = "crowdstrike"
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist."
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "crowdstrike-shra"
}

variable "chart_repository" {
  description = "Helm repository URL for the CrowdStrike SHRA chart."
  type        = string
}

variable "chart_name" {
  description = "Helm chart name."
  type        = string
}

variable "chart_version" {
  description = "Helm chart version."
  type        = string
}

variable "values_file_path" {
  description = "Path to an optional Helm values file."
  type        = string
  default     = ""
}

variable "values_yaml" {
  description = "Optional inline Helm values as a YAML string."
  type        = string
  default     = ""
}

variable "create_k8s_secrets" {
  description = "Create Kubernetes secrets for the SHRA deployment."
  type        = bool
  default     = true
}

variable "crowdstrike_secret_name" {
  description = "Kubernetes secret name for CrowdStrike API credentials."
  type        = string
  default     = "CROWDSTRIKE_CREDENTIALS"
}

variable "artifactory_secret_name" {
  description = "Kubernetes secret name for Artifactory credentials."
  type        = string
  default     = "ARTIFACTORY_CREDS"
}

variable "crowdstrike_credentials_json" {
  description = "JSON for CrowdStrike API credentials (CLIENT_ID/SECRET)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "artifactory_creds_json" {
  description = "JSON for Artifactory credentials (USERNAME/PASSWORD)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "timeout_seconds" {
  description = "Helm release timeout in seconds."
  type        = number
  default     = 600
}
