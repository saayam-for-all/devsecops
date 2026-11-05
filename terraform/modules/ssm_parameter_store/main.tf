# --------------------------------------------------------------------------------------------------
# Module: AWS Systems Manager (SSM) Parameter Store
# Description: Modular provisioning of hierarchical application configuration and secrets for
#              Saayam microservices using /{team-name}/{service-name}/{parameter} hierarchy.
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
data "aws_region" "current" {}

locals {
  # Standard alias/aws/ssm is free and requires no KMS monthly fee ($1/mo saved per CMK)
  active_kms_key_arn = var.create_kms_key ? aws_kms_key.ssm[0].arn : (var.kms_key_arn != "" ? var.kms_key_arn : null)

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "devsecops"
      Component   = "ssm-parameter-store"
    }
  )
}

# Optional Customer Managed KMS Key (Only if explicitly enabled; otherwise default AWS-managed key is used)
resource "aws_kms_key" "ssm" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key for Saayam SSM SecureString parameters (${var.environment})"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSSMServiceUsage"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_kms_alias" "ssm" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/saayam-${var.environment}-ssm"
  target_key_id = aws_kms_key.ssm[0].key_id
}

# --------------------------------------------------------------------------------------------------
# Standard Hierarchical SSM Parameters: /{team-name}/{service-name}/{parameter}
# --------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameters

  name = var.prefix_environment ? (
    "/${var.environment}/${lower(each.value.team)}/${lower(each.value.service)}/${each.key}"
  ) : (
    "/${lower(each.value.team)}/${lower(each.value.service)}/${each.key}"
  )

  description = each.value.description != "" ? each.value.description : "Parameter ${each.key} for ${each.value.service} (${each.value.team})"
  type        = each.value.type
  value       = each.value.value
  tier        = each.value.tier
  data_type   = each.value.data_type
  overwrite   = each.value.overwrite

  # Use KMS key only for SecureString parameters
  key_id = each.value.type == "SecureString" ? (
    each.value.kms_key_id != "" ? each.value.kms_key_id : local.active_kms_key_arn
  ) : null

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Team    = each.value.team
      Service = each.value.service
      Tier    = each.value.tier
    }
  )
}
