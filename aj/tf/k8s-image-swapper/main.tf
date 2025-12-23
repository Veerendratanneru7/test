locals {
  protected_namespace_filters = [
    for ns in var.protected_namespaces : "obj.metadata.namespace == '${ns}'"
  ]
  
  target_namespace_filters = length(var.target_namespaces) > 0 ? [
    "!(${join(" || ", [for ns in var.target_namespaces : "obj.metadata.namespace == '${ns}'"])})"
  ] : []
  
  all_filters = concat(
    local.protected_namespace_filters,
    local.target_namespace_filters,
    [
      "contains(container.image, '.dkr.ecr.') && contains(container.image, '.amazonaws.com')"
    ]
  )

  filter_rules = [
    for filter in local.all_filters : {
      jmespath = filter
    }
  ]

  rewrite_rules = [
    {
      source = "v-gha.artifactory.aws.venmo.biz/docker"
      target = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/sre/prod/docker/gha/node"
    },
    {
      source = "v-gha.artifactory.aws.venmo.biz/v-actions-runner"
      target = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/sre/prod/docker/gha/node"
    },
    {
      source = "v-gha.artifactory.aws.venmo.biz/v-gha-husky"
      target = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/sre/prod/docker/gha/node"
    },
    {
      source = "v-gha.artifactory.aws.venmo.biz/gha-runner-scale-set-controller"
      target = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/sre/prod/docker/gha/node"
    }
  ]

  helm_values = {
    config = {
      dryRun          = var.dry_run
      logLevel        = "debug"
      logFormat       = "console"
      imageSwapPolicy = var.image_swap_policy
      imageCopyPolicy = var.image_copy_policy
      source = {
        filters = local.filter_rules
      }
      target = {
        type = "aws"
        aws = {
          accountId = var.aws_account_id
          region    = var.region
        }
      }
    }
    imageSwapper = {
      enabled = var.enable_mutations
      rewrite = {
        rulesMatchRegex = true
        rules           = local.rewrite_rules
      }
    }
  }
}

resource "helm_release" "k8s_image_swapper" {
  name       = var.k8s_image_swapper_name
  namespace  = var.k8s_image_swapper_namespace
  repository = "https://artifactory.aws.venmo.biz/artifactory/helm-external-local/"
  chart      = "k8s-image-swapper"
  version    = var.k8s_image_swapper_chart_version

  values = [yamlencode(local.helm_values)]

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

  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

data "aws_iam_role" "k8s_image_swapper_existing" {
  name = "${var.cluster_name}-${var.k8s_image_swapper_name}"

  depends_on = [aws_iam_role.k8s_image_swapper]
}
