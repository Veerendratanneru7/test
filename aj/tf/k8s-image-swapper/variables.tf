variable "cluster_oidc_provider" {
  description = "The OIDC provider URL of your EKS cluster (e.g., from an EKS module output)."
  type        = string
}

variable "cluster_name" {
  description = "The name of your EKS cluster."
  type        = string
}

variable "region" {
  description = "The AWS region where your EKS cluster is deployed."
  type        = string
}

variable "k8s_image_swapper_namespace" {
  description = "The Kubernetes namespace where k8s-image-swapper will be installed."
  type        = string
  default     = "kube-system"
}

variable "k8s_image_swapper_name" {
  description = "The name for the k8s-image-swapper Helm release and service account."
  type        = string
  default     = "k8s-image-swapper"
}

variable "k8s_image_swapper_chart_version" {
  description = "The version of the k8s-image-swapper Helm chart."
  type        = string
  default     = "1.11.0"
}

variable "aws_account_id" {
  description = "The AWS account ID where the EKS cluster is deployed."
  type        = string
  default     = "787388907485"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication."
  type        = string
  default     = "fnd-ci"
}

variable "dry_run" {
  description = "Enable dry-run mode (Phase 1). When true, webhook logs mutations but does not execute them."
  type        = bool
  default     = true
}

variable "enable_mutations" {
  description = "Enable actual mutations (Phase 2+). When false, webhook runs in dry-run/evaluate mode only."
  type        = bool
  default     = false
}

variable "protected_namespaces" {
  description = "List of Kubernetes namespaces that must NOT be mutated by the webhook (e.g., kube-system, kube-public)."
  type        = list(string)
  default     = ["kube-system", "kube-public", "kube-node-lease"]
}

variable "target_namespaces" {
  description = "List of namespaces to allow mutations in (Phase 2: limited scope, e.g., non-critical test namespaces)."
  type        = list(string)
  default     = []
}

variable "image_swap_policy" {
  description = "Image swap strategy: 'always' or 'exists'. 'exists' only swaps if image exists in target registry (recommended for safe rollout)."
  type        = string
  default     = "exists"
  validation {
    condition     = contains(["always", "exists"], var.image_swap_policy)
    error_message = "image_swap_policy must be 'always' or 'exists'."
  }
}

variable "image_copy_policy" {
  description = "Image copy strategy: 'delayed', 'immediate', 'force', or 'none'."
  type        = string
  default     = "delayed"
  validation {
    condition     = contains(["delayed", "immediate", "force", "none"], var.image_copy_policy)
    error_message = "image_copy_policy must be one of: delayed, immediate, force, none."
  }
}
