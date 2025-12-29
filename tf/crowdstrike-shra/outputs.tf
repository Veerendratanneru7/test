output "namespace" {
  description = "Namespace where SHRA is deployed."
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.shra.name
}

output "crowdstrike_secret_name" {
  description = "Kubernetes secret name for CrowdStrike API credentials."
  value       = var.crowdstrike_secret_name
}

output "artifactory_secret_name" {
  description = "Kubernetes secret name for Artifactory credentials."
  value       = var.artifactory_secret_name
}
