# EKS Cluster Configuration
cluster_oidc_provider = "oidc.eks.us-east-1.amazonaws.com/id/1188191553855BDB8BCCA1497895B27CF"
cluster_name         = "gha-venmo-ghe-dev-shared-ucl"
region               = "us-east-1"

# Namespace and Helm Release Name
k8s_image_swapper_namespace = "kube-system"
k8s_image_swapper_name      = "k8s-image-swapper"

# AWS Account Information
aws_account_id = "787388907485"
aws_profile    = "fnd-ci"

# Helm Chart Version (optional, if not hardcoded in the Terraform configuration)
k8s_image_swapper_chart_version = "1.11.0"

# Phase 1: Dry-Run Deployment
# In dry-run mode, the webhook logs all mutations it would make but does NOT execute them.
dry_run = false
enable_mutations = true

protected_namespaces = ["kube-system", "kube-public", "kube-node-lease"]

# Phase 2: When ready to enable mutations, set target_namespaces to non-critical test namespaces
target_namespaces = []

# Image swap and copy policies (safe defaults for staged rollout)
image_swap_policy = "exists"    
image_copy_policy = "delayed"   
