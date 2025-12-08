variable "aws_account_id" {
  description = "Target AWS account ID (optional). If empty, will use the account from current AWS credentials."
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region (optional). If empty, will use the region from AWS provider / environment."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Cluster name used for resource naming"
  type        = string
  default     = "mycluster"
}

variable "k8s_image_swapper_name" {
  description = "Helm release name for k8s-image-swapper"
  type        = string
  default     = "k8s-image-swapper"
}

variable "namespace" {
  description = "Namespace for the Helm release (avoid kube-system)"
  type        = string
  default     = "infra"
}

variable "allowed_test_namespaces" {
  description = "Namespaces allowed initially (whitelist) for testing/phase1"
  type        = list(string)
  default     = ["image-swapper-test"]
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA (if using EKS). Leave empty if not using IRSA"
  type        = string
  default     = ""
}
