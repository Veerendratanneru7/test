terraform {
  required_version = "~> 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.7.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

locals {
  cluster_host           = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  cluster_token          = data.aws_eks_cluster_auth.cluster.token
}

provider "kubernetes" {
  host                   = local.cluster_host
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_token
}

provider "kubectl" {
  host                   = local.cluster_host
  cluster_ca_certificate = local.cluster_ca_certificate
  token                  = local.cluster_token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_host
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = local.cluster_token
  }
}
