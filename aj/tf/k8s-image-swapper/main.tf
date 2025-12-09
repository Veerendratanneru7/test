locals {
  # Build JMESPath filters for protected namespaces (match = NOT processed)
  protected_namespace_filters = [
    for ns in var.protected_namespaces : "obj.metadata.namespace == '${ns}'"
  ]
  
  # If target_namespaces is specified (Phase 2), build allowlist filter
  target_namespace_filters = length(var.target_namespaces) > 0 ? [
    "!(${join(" || ", [for ns in var.target_namespaces : "obj.metadata.namespace == '${ns}'"])})"
  ] : []
  
  # Combine all filters
  all_filters = concat(
    local.protected_namespace_filters,
    local.target_namespace_filters,
    [
      "contains(container.image, '.dkr.ecr.') && contains(container.image, '.amazonaws.com')"
    ]
  )
  
  # Build YAML filters list
  filters_yaml = join("\n      ", [
    for filter in local.all_filters : "- jmespath: \"${filter}\""
  ])
}

resource "helm_release" "k8s_image_swapper" {
  name       = var.k8s_image_swapper_name
  namespace  = var.k8s_image_swapper_namespace
  repository = "https://artifactory.aws.venmo.biz/artifactory/helm-external-local/"
  chart      = "k8s-image-swapper"
  version    = var.k8s_image_swapper_chart_version

  values = [<<YAML
config:
  dryRun: ${var.dry_run}
  logLevel: debug
  logFormat: console
  imageSwapPolicy: ${var.image_swap_policy}
  imageCopyPolicy: ${var.image_copy_policy}

  source:
    # Filters to control what pods will be processed.
    # A matching filter means the pod will NOT be processed.
    filters:
      ${local.filters_yaml}

  target:
    type: aws
    aws:
      accountId: "${var.aws_account_id}"
      region: "${var.region}"

imageSwapper:
  enabled: ${var.enable_mutations}
  rewrite:
    rulesMatchRegex: true
    rules:
      - source: "ghcr.io/actions/gha-runner-scale-set-controller"
        target: "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/gha-runner-scale-set-controller"
YAML
  ]

  timeout = 300
}

resource "aws_iam_role_policy" "k8s_image_swapper" {
  name = "${var.cluster_name}-${var.k8s_image_swapper_name}"
  role = aws_iam_role.k8s_image_swapper.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": [
        "arn:aws:ecr:*:${var.aws_account_id}:repository/*",
        "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "k8s_image_swapper" {
  name = "${var.cluster_name}-${var.k8s_image_swapper_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(var.cluster_oidc_provider, "https://", "") }"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(var.cluster_oidc_provider, "https://", "")}:sub": "system:serviceaccount:${var.k8s_image_swapper_namespace}:${var.k8s_image_swapper_name}"
        }
      }
    }
  ]
}
EOF
}
