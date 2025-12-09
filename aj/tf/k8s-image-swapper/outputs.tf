output "k8s_image_swapper_iam_role_arn" {
  description = "The ARN of the IAM role created for k8s-image-swapper."
  value       = aws_iam_role.k8s_image_swapper.arn
}
