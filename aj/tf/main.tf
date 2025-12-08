# Helm release for k8s-image-swapper
resource "helm_release" "k8s_image_swapper" {
  name       = var.k8s_image_swapper_name
  namespace  = var.namespace
  repository = "https://artifactory.aws.venmo.biz/artifactory/helm-external-local/" 
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
  # Filters: by default if a condition matches the pod will NOT be processed.
  # These are JMESPath expressions. In phase1 allow only the test namespace(s).
  filters:
    - jmespath: "obj.metadata.namespace != 'kube-system'"
    - jmespath: "contains(['${join("','", var.allowed_test_namespaces)}'], obj.metadata.namespace) == `true`"

target:
  type: aws
  aws:
    accountId: "${var.aws_account_id}"
    region: ${var.region}

imageSwapper:
  enabled: false
  rewrite:
    rulesMatchRegex: true
    rules:
      # Example rewrite rule - add more as needed. Adjust source/target strings.
      - source: "ghcr.io/actions/gha-runner-scale-set-controller"
        target: "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/ghcr.io/actions/gha-runner-scale-set-controller"

secretReader:
  enabled: true

serviceAccount:
  create: true
  annotations:
    # If using EKS IRSA annotate the SA to assume the created role.
    eks.amazonaws.com/role-arn: "arn:aws:iam::${var.aws_account_id}:role/${var.cluster_name}-${var.k8s_image_swapper_name}-role"
YAML
  ]
}

resource "aws_iam_role" "k8s_image_swapper" {
  name = "${var.cluster_name}-${var.k8s_image_swapper_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn != "" ? var.oidc_provider_arn : ""
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = var.oidc_provider_arn != "" ? {
          StringLike = {
            # Replace <namespace> and <serviceaccount> if you require exact conditions.
            "${replace(var.oidc_provider_arn, "arn:aws:iam::", "")}:sub" = "system:serviceaccount:*:${var.k8s_image_swapper_name}"
          }
        } : {}
      }
    ]
  })
}

# IAM policy for ECR operations
resource "aws_iam_policy" "k8s_image_swapper_policy" {
  name        = "${var.cluster_name}-${var.k8s_image_swapper_name}-policy"
  description = "ECR access policy for k8s-image-swapper"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = ""
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid = ""
        Effect = "Allow"
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
        ]
        Resource = "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_k8s_image_swapper" {
  role       = aws_iam_role.k8s_image_swapper.name
  policy_arn = aws_iam_policy.k8s_image_swapper_policy.arn
}
