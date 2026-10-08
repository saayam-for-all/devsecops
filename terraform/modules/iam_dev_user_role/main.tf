# --------------------------------------------------------------------------------------------------
# Terraform Module: Standardized IAM Developer User & Project Role Setup
# Description: Provisions a least-privilege dev IAM user, secure credential storage in AWS Secrets
#              Manager, and an assumeable project role with scoped resource permissions.
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

# Current AWS Account and Region references
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "saayam-${var.environment}-${var.project_name}"
  user_name   = "saayam-${var.environment}-${var.developer_username}"
  role_name   = var.custom_role_name != "" ? var.custom_role_name : "${local.name_prefix}-${var.role_purpose}-role"
  secret_name = "saayam/${var.environment}/users/${var.developer_username}/credentials"
  
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.developer_username
    }
  )
}

# --------------------------------------------------------------------------------------------------
# 1. Developer IAM User (No direct AWS permissions except sts:AssumeRole and reading own credentials)
# --------------------------------------------------------------------------------------------------
resource "aws_iam_user" "developer" {
  name          = local.user_name
  path          = "/saayam/developers/"
  force_destroy = var.force_destroy_user

  tags = local.common_tags
}

# Programmatic Access Key for the Developer
resource "aws_iam_access_key" "developer_key" {
  count = var.create_access_key ? 1 : 0
  user  = aws_iam_user.developer.name
}

# --------------------------------------------------------------------------------------------------
# 2. Secure Credential Storage in AWS Secrets Manager (Encrypted with KMS)
# --------------------------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "developer_credentials" {
  count                   = var.create_access_key && var.store_in_secrets_manager ? 1 : 0
  name                    = local.secret_name
  description             = "Programmatic AWS credentials for developer ${var.developer_username} in ${var.environment}"
  recovery_window_in_days = var.secret_recovery_window_days
  kms_key_id              = var.kms_key_id != "" ? var.kms_key_id : null

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "developer_credentials" {
  count     = var.create_access_key && var.store_in_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.developer_credentials[0].id
  secret_string = jsonencode({
    username              = aws_iam_user.developer.name
    developer_email       = var.developer_email
    aws_access_key_id     = aws_iam_access_key.developer_key[0].id
    aws_secret_access_key = aws_iam_access_key.developer_key[0].secret
    role_to_assume_arn    = aws_iam_role.project_role.arn
    aws_region            = data.aws_region.current.name
    environment           = var.environment
    project               = var.project_name
  })
}

# --------------------------------------------------------------------------------------------------
# 3. Project IAM Role (Assumed by the Developer User for specific project tasks)
# --------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid     = "AllowDevUserToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.developer.arn]
    }

    # Optional IP restriction or MFA requirement condition if configured
    dynamic "condition" {
      for_each = length(var.allowed_ip_cidrs) > 0 ? [1] : []
      content {
        test     = "IpAddress"
        variable = "aws:SourceIp"
        values   = var.allowed_ip_cidrs
      }
    }
  }
}

resource "aws_iam_role" "project_role" {
  name                 = local.role_name
  path                 = "/saayam/roles/"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  max_session_duration = var.max_session_duration_seconds
  description          = "Scoped role for ${var.project_name} development assumed by ${aws_iam_user.developer.name}"

  tags = local.common_tags
}

# --------------------------------------------------------------------------------------------------
# 4. Scoped Resource Policies (e.g. S3 Profile Picture Uploads / Microservice Resources)
# --------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "scoped_s3_permissions" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0

  # S3 Bucket Level Permissions (List Bucket)
  statement {
    sid    = "AllowS3ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = var.s3_bucket_arns
  }

  # S3 Object Level Permissions (Scoped to defined prefix or all objects in the bucket)
  statement {
    sid    = "AllowS3ObjectOperations"
    effect = "Allow"
    actions = var.s3_allowed_actions
    resources = [
      for bucket in var.s3_bucket_arns : "${bucket}/${var.s3_object_prefix_pattern}"
    ]
  }
}

resource "aws_iam_policy" "scoped_s3_policy" {
  count       = length(var.s3_bucket_arns) > 0 ? 1 : 0
  name        = "${local.role_name}-s3-policy"
  path        = "/saayam/policies/"
  description = "Scoped S3 access policy for ${local.role_name}"
  policy      = data.aws_iam_policy_document.scoped_s3_permissions[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "scoped_s3_attachment" {
  count      = length(var.s3_bucket_arns) > 0 ? 1 : 0
  role       = aws_iam_role.project_role.name
  policy_arn = aws_iam_policy.scoped_s3_policy[0].arn
}

# Optional Custom Additional Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.project_role.name
  policy_arn = each.value
}

# --------------------------------------------------------------------------------------------------
# 5. Developer User Least-Privilege Permissions: Can ONLY Assume the Project Role & Read Their Secret
# --------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "developer_user_minimal_policy" {
  # 1. Allow assuming their specific assigned project role
  statement {
    sid       = "AllowAssumeProjectRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.project_role.arn]
  }

  # 2. Allow developer to read only their own secret from Secrets Manager
  dynamic "statement" {
    for_each = var.store_in_secrets_manager ? [1] : []
    content {
      sid    = "AllowReadOwnSecret"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [aws_secretsmanager_secret.developer_credentials[0].arn]
    }
  }

  # 3. Allow managing own access keys and password if self-service is enabled
  statement {
    sid    = "AllowManageOwnCredentials"
    effect = "Allow"
    actions = [
      "iam:GetUser",
      "iam:ChangePassword",
      "iam:GetAccessKeyLastUsed"
    ]
    resources = [aws_iam_user.developer.arn]
  }
}

resource "aws_iam_user_policy" "developer_user_policy" {
  name   = "${aws_iam_user.developer.name}-minimal-policy"
  user   = aws_iam_user.developer.name
  policy = data.aws_iam_policy_document.developer_user_minimal_policy.json
}
