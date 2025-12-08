variable "aws_account_id" {
  description = "Target AWS account ID where ECR repos exist"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Cluster name used for resource naming"
  type        = string
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
  description = "List of namespaces allowed in initial dry-run/test phase"
  type        = list(string)
  default     = ["image-swapper-test"]
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN (for IRSA). Leave empty if not using IRSA"
  type        = string
  default     = ""
}
