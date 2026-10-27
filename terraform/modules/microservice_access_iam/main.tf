# --------------------------------------------------------------------------------------------------
# Module: Microservice Least-Privilege IAM Access (ElastiCache & SSM)
# Description: Generates scoped zero-privilege IAM policies and roles granting microservices
#              read-only access to their team-level SSM parameters and connection access to ElastiCache.
#              Enforces multi-region consistency across Virginia (us-east-1) and Ireland (eu-west-1).
# --------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  role_name   = "${var.name_prefix}-${var.environment}-${var.team_name}-${var.service_name}-role"
  policy_name = "${var.name_prefix}-${var.environment}-${var.team_name}-${var.service_name}-ssm-cache-policy"

  # Determine parameter patterns: default to team namespace (e.g. /volunteer/*)
  base_patterns = length(var.ssm_path_patterns) > 0 ? var.ssm_path_patterns : ["/${lower(var.team_name)}/*"]
  all_patterns = var.allow_shared_team_parameters ? concat(local.base_patterns, ["/shared/*"]) : local.base_patterns

  # Flatten SSM resource ARNs across all requested regions (Virginia + Ireland)
  ssm_parameter_arns = distinct(flatten([
    for region in var.regions : [
      for pattern in local.all_patterns : "arn:aws:ssm:${region}:${data.aws_caller_identity.current.account_id}:parameter${startswith(pattern, "/") ? pattern : "/${pattern}"}"
    ]
  ]))

  # Flatten ElastiCache resource ARNs across all requested regions
  cluster_ids = length(var.elasticache_replication_group_ids) > 0 ? var.elasticache_replication_group_ids : ["*"]
  elasticache_arns = distinct(flatten([
    for region in var.regions : flatten([
      [for cid in local.cluster_ids : "arn:aws:elasticache:${region}:${data.aws_caller_identity.current.account_id}:replicationgroup:${cid}"],
      ["arn:aws:elasticache:${region}:${data.aws_caller_identity.current.account_id}:user:*"]
    ])
  ]))

  # Default KMS Decrypt targets
  kms_arns = length(var.kms_key_arns) > 0 ? var.kms_key_arns : [
    for region in var.regions : "arn:aws:kms:${region}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"
  ]

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Team        = var.team_name
      Service     = var.service_name
      ManagedBy   = "Terraform"
      Repository  = "devsecops"
    }
  )
}

# --------------------------------------------------------------------------------------------------
# 1. Least-Privilege IAM Policy for Microservice
#    - Scoped strictly to team SSM parameter hierarchy (e.g. /{team}/*)
#    - Allows decryption using specified KMS key
#    - Allows ElastiCache connection on designated replication groups
# --------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "microservice_permissions" {
  # Granular SSM Read Permissions (Strict Team Isolation)
  statement {
    sid    = "AllowTeamScopedSSMRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = local.ssm_parameter_arns
  }

  # Allow SSM parameter discovery (team level)
  statement {
    sid    = "AllowSSMDescribeParameters"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ssm:ResourceTag/Team"
      values   = [var.team_name, "shared", "DevSecOps"]
    }
  }

  # KMS Decryption for SecureString Parameters
  statement {
    sid    = "AllowKMSDecryptForSSMSecrets"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = local.kms_arns
  }

  # ElastiCache Connect Permission (Zero-Privilege IAM Auth)
  statement {
    sid    = "AllowElastiCacheConnect"
    effect = "Allow"
    actions = [
      "elasticache:Connect"
    ]
    resources = local.elasticache_arns
  }
}

resource "aws_iam_policy" "microservice_policy" {
  name        = local.policy_name
  description = "Least-privilege policy for ${var.team_name}-${var.service_name} accessing SSM and ElastiCache"
  policy      = data.aws_iam_policy_document.microservice_permissions.json

  tags = local.common_tags
}

# --------------------------------------------------------------------------------------------------
# 2. Microservice Execution IAM Role
#    - Supports EKS IRSA (Kubernetes Service Account)
#    - Supports AWS ECS Tasks and Lambda execution
#    - Supports developer/runner STS AssumeRole
# --------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role_trust" {
  # Trusted AWS Service Principals (ECS, Lambda, etc.)
  dynamic "statement" {
    for_each = length(var.trusted_service_principals) > 0 ? [1] : []
    content {
      sid     = "AllowServiceAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = var.trusted_service_principals
      }
    }
  }

  # Trusted IAM User/Role Principals (Developers, CI/CD runners)
  dynamic "statement" {
    for_each = length(var.trusted_role_arns) > 0 ? [1] : []
    content {
      sid     = "AllowIAMPrincipalsAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.trusted_role_arns
      }
    }
  }

  # EKS IRSA OIDC Federated Trust (If EKS OIDC provider configured)
  dynamic "statement" {
    for_each = var.eks_oidc_provider_arn != "" && var.eks_oidc_issuer_url != "" ? [1] : []
    content {
      sid     = "AllowEKSIRSATrust"
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [var.eks_oidc_provider_arn]
      }

      condition {
        test     = "StringEquals"
        variable = "${var.eks_oidc_issuer_url}:sub"
        values   = ["system:serviceaccount:${var.eks_service_account_namespace}:${var.eks_service_account_name != "" ? var.eks_service_account_name : var.service_name}"]
      }

      condition {
        test     = "StringEquals"
        variable = "${var.eks_oidc_issuer_url}:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role" "microservice_role" {
  count                = var.create_role ? 1 : 0
  name                 = local.role_name
  description          = "Least-privilege role for ${var.team_name} ${var.service_name} microservice"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_trust.json
  max_session_duration = var.max_session_duration

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "attach_access_policy" {
  count      = var.create_role ? 1 : 0
  role       = aws_iam_role.microservice_role[0].name
  policy_arn = aws_iam_policy.microservice_policy.arn
}
