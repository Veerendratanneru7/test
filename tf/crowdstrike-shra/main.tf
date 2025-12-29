locals {
  helm_values = compact([
    var.values_yaml,
    var.values_file_path != "" ? file(var.values_file_path) : ""
  ])
}

resource "kubernetes_namespace" "shra" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "crowdstrike_credentials" {
  count = var.create_k8s_secrets && var.crowdstrike_credentials_json != "" ? 1 : 0

  metadata {
    name      = var.crowdstrike_secret_name
    namespace = var.namespace
  }

  data = {
    CROWDSTRIKE_CREDENTIALS = var.crowdstrike_credentials_json
  }

  type = "Opaque"
}

resource "kubernetes_secret" "artifactory_creds" {
  count = var.create_k8s_secrets && var.artifactory_creds_json != "" ? 1 : 0

  metadata {
    name      = var.artifactory_secret_name
    namespace = var.namespace
  }

  data = {
    ARTIFACTORY_CREDS = var.artifactory_creds_json
  }

  type = "Opaque"
}

resource "helm_release" "shra" {
  name       = var.release_name
  namespace  = var.namespace
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  values  = local.helm_values
  timeout = var.timeout_seconds

  depends_on = [
    kubernetes_namespace.shra,
    kubernetes_secret.crowdstrike_credentials,
    kubernetes_secret.artifactory_creds
  ]
}
