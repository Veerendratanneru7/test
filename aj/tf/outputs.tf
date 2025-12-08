output "k8s_image_swapper_iam_role_arn" {
  description = "ARN of the IAM role for k8s-image-swapper"
  value       = aws_iam_role.k8s_image_swapper.arn
}

output "k8s_image_swapper_policy_arn" {
  description = "ARN of the IAM policy attached"
  value       = aws_iam_policy.k8s_image_swapper_policy.arn
}

output "k8s_image_swapper_release_name" {
  value       = helm_release.k8s_image_swapper.name
  description = "Helm release name"
}
