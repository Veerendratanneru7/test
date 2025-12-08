# Helm release for k8s-image-swapper
resource "helm_release" "k8s_image_swapper" {
  name       = var.k8s_image_swapper_name
  namespace  = var.namespace
  repository = "https://artifactory.aws.venmo.biz/artifactory/helm-external-local/" # replace if needed
  chart      = "k8s-image-swapper"
  version    = "1.11.0"

  values = [
    <<YAML
config:
  # Phase 1: start in dry-run for staging validation
  dryRun: true
  logLevel: debug
  logFormat: console
  imageSwapPolicy: exists
  imageCopyPolicy: delayed
  imageCopyDeadline: 30s

source:
  # Filters: by default a matching condition will EXCLUDE the pod. Use whitelist approach.
  filters:
    - jmespath: "obj.metadata.namespace != 'kube-system'"
    - jmespath: "contains(['${local.allowed_ns_jmespath_list}'], obj.metadata.namespace) == `true`"

target:
  type: aws
  aws:
    accountId: "${local.effective_aws_account_id}"
    region: ${local.effective_region}

imageSwapper:
  enabled: false
  rewrite:
    rulesMatchRegex: true
    rules:
      - source: "ghcr.io/actions/gha-runner-scale-set-controller"
        target: "${local.effective_aws_account_id}.dkr.ecr.${local.effective_region}.amazonaws.com/ghcr.io/actions/gha-runner-scale-set-controller"

secretReader:
  enabled: true

serviceAccount:
  create: true
  annotations:
    # If IRSA is used, ensure oidc_provider_arn matches and terraform creates the role below.
    eks.amazonaws.com/role-arn: "arn:aws:iam::${local.effective_aws_account_id}:role/${var.cluster_name}-${var.k8s_image_swapper_name}-role"
YAML
  ]
}

# Create IAM role only if oidc_provider_arn is provided (IRSA)
resource "aws_iam_role" "k8s_image_swapper" {
  count = var.oidc_provider_arn != "" ? 1 : 0
  name  = "${var.cluster_name}-${var.k8s_image_swapper_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # narrow to service account name; if you want a specific namespace replace the '*'
            "${replace(var.oidc_provider_arn, "arn:aws:iam::", "")}:sub" = "system:serviceaccount:*:${var.k8s_image_swapper_name}"
          }
        }
      }
    ]
  })
}

# IAM policy for ECR operations (always create - safe)
resource "aws_iam_policy" "k8s_image_swapper_policy" {
  name        = "${var.cluster_name}-${var.k8s_image_swapper_name}-policy"
  description = "ECR access policy for k8s-image-swapper"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Sid = "",
        Effect = "Allow",
        Action = [
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:CreateRepository"
        ],
        Resource = "arn:aws:ecr:${local.effective_region}:${local.effective_aws_account_id}:repository/*"
      }
    ]
  })
}

# Attach policy to role only if role exists
resource "aws_iam_role_policy_attachment" "attach_k8s_image_swapper" {
  count      = var.oidc_provider_arn != "" ? 1 : 0
  role       = aws_iam_role.k8s_image_swapper[0].name
  policy_arn = aws_iam_policy.k8s_image_swapper_policy.arn
}
