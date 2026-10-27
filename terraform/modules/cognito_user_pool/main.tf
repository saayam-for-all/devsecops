# --------------------------------------------------------------------------------------------------
# Terraform Module: AWS Cognito User Pool with Advanced Security & Audit Logging
# Description: Provisions a standardized Cognito User Pool with schema replication, MFA, password
#              policies, Advanced Security Features (ENFORCED/AUDIT), App Clients (e.g. Netlify),
#              CloudTrail audit event routing, and CloudWatch log streams for Lambda triggers.
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
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "devsecops"
      Component   = "cognito-user-pool"
      PoolName    = var.user_pool_name
    }
  )

  # CloudTrail audit bucket name (must be globally unique)
  cloudtrail_bucket_name = var.audit_bucket_name != "" ? var.audit_bucket_name : (
    lower("saayam-audit-${var.environment}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}")
  )
}

# --------------------------------------------------------------------------------------------------
# 1. Cognito User Pool Core Resource
# --------------------------------------------------------------------------------------------------
resource "aws_cognito_user_pool" "this" {
  name                     = var.user_pool_name
  deletion_protection      = var.deletion_protection
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Multi-Factor Authentication (MFA) Configuration
  mfa_configuration = var.mfa_configuration

  dynamic "software_token_mfa_configuration" {
    for_each = var.enable_software_token_mfa ? [1] : []
    content {
      enabled = true
    }
  }

  # Account Recovery Setting
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  # Password Policy
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = var.password_require_lowercase
    require_numbers                  = var.password_require_numbers
    require_symbols                  = var.password_require_symbols
    require_uppercase                = var.password_require_uppercase
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  # Self-Service Registration / Admin Create User Configuration
  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only
  }

  # Email Verification Configuration
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = var.email_verification_subject
    email_message        = var.email_verification_message
  }

  email_configuration {
    email_sending_account = var.email_sending_account
  }

  username_configuration {
    case_sensitive = false
  }

  # Cognito Advanced Security Features (ENFORCED, AUDIT, or OFF)
  dynamic "user_pool_add_ons" {
    for_each = var.advanced_security_mode != "OFF" ? [1] : []
    content {
      advanced_security_mode = var.advanced_security_mode
    }
  }

  # ------------------------------------------------------------------------------------------------
  # Standard Schema Attributes
  # ------------------------------------------------------------------------------------------------
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "phone_number"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  schema {
    name                     = "given_name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 128
    }
  }

  schema {
    name                     = "family_name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 128
    }
  }

  # ------------------------------------------------------------------------------------------------
  # Custom Schema Attributes (Replicating DevUserPool schema for Saayam Roles & Volunteer metadata)
  # ------------------------------------------------------------------------------------------------
  schema {
    name                     = "role"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  schema {
    name                     = "organization_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 64
    }
  }

  schema {
    name                     = "volunteer_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 64
    }
  }

  schema {
    name                     = "kyc_verified"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 10
    }
  }

  # Additional dynamic custom attributes
  dynamic "schema" {
    for_each = var.additional_custom_attributes
    content {
      name                     = schema.value.name
      attribute_data_type      = lookup(schema.value, "attribute_data_type", "String")
      developer_only_attribute = false
      mutable                  = lookup(schema.value, "mutable", true)
      required                 = lookup(schema.value, "required", false)

      dynamic "string_attribute_constraints" {
        for_each = lookup(schema.value, "attribute_data_type", "String") == "String" ? [1] : []
        content {
          min_length = lookup(schema.value, "min_length", 0)
          max_length = lookup(schema.value, "max_length", 256)
        }
      }
    }
  }

  # ------------------------------------------------------------------------------------------------
  # Attached Lambda Triggers
  # ------------------------------------------------------------------------------------------------
  dynamic "lambda_config" {
    for_each = length(keys(var.lambda_triggers)) > 0 ? [1] : []
    content {
      pre_sign_up                    = lookup(var.lambda_triggers, "pre_sign_up", null)
      post_confirmation              = lookup(var.lambda_triggers, "post_confirmation", null)
      pre_authentication             = lookup(var.lambda_triggers, "pre_authentication", null)
      post_authentication            = lookup(var.lambda_triggers, "post_authentication", null)
      pre_token_generation           = lookup(var.lambda_triggers, "pre_token_generation", null)
      user_migration                 = lookup(var.lambda_triggers, "user_migration", null)
      custom_message                 = lookup(var.lambda_triggers, "custom_message", null)
      define_auth_challenge          = lookup(var.lambda_triggers, "define_auth_challenge", null)
      create_auth_challenge          = lookup(var.lambda_triggers, "create_auth_challenge", null)
      verify_auth_challenge_response = lookup(var.lambda_triggers, "verify_auth_challenge_response", null)
    }
  }

  tags = local.common_tags
}

# --------------------------------------------------------------------------------------------------
# 2. Primary App Client (e.g. for QA_saayam-netlify.app single page application)
# --------------------------------------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "primary_app_client" {
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.this.id

  # SPAs / Public web apps do not use a client secret
  generate_secret = var.client_generate_secret

  # Security hardening against user enumeration
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = var.client_explicit_auth_flows

  supported_identity_providers = var.client_supported_identity_providers

  # Callback & Logout URLs for Netlify Web App
  callback_urls = var.client_callback_urls
  logout_urls   = var.client_logout_urls

  # OAuth 2.0 / OIDC Flow Configurations
  allowed_oauth_flows                  = var.client_allowed_oauth_flows
  allowed_oauth_scopes                 = var.client_allowed_oauth_scopes
  allowed_oauth_flows_user_pool_client = var.client_allowed_oauth_flows_user_pool_client

  # Token Lifetimes
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  access_token_validity  = var.access_token_validity
  id_token_validity      = var.id_token_validity
  refresh_token_validity = var.refresh_token_validity
}

# Additional App Clients (e.g., machine-to-machine, backend services)
resource "aws_cognito_user_pool_client" "additional_clients" {
  for_each     = var.additional_app_clients
  name         = each.key
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret               = lookup(each.value, "generate_secret", true)
  prevent_user_existence_errors = lookup(each.value, "prevent_user_existence_errors", "ENABLED")
  explicit_auth_flows           = lookup(each.value, "explicit_auth_flows", var.client_explicit_auth_flows)
  supported_identity_providers  = lookup(each.value, "supported_identity_providers", ["COGNITO"])
  callback_urls                 = lookup(each.value, "callback_urls", [])
  logout_urls                   = lookup(each.value, "logout_urls", [])
  allowed_oauth_flows           = lookup(each.value, "allowed_oauth_flows", ["code"])
  allowed_oauth_scopes          = lookup(each.value, "allowed_oauth_scopes", ["email", "openid"])
  allowed_oauth_flows_user_pool_client = lookup(each.value, "allowed_oauth_flows_user_pool_client", false)
}

# Optional Hosted UI Domain Prefix
resource "aws_cognito_user_pool_domain" "this" {
  count        = var.domain_prefix != "" ? 1 : 0
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

# --------------------------------------------------------------------------------------------------
# 3. CloudWatch Log Streams & Groups for Cognito Attached Lambda Triggers
# --------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda_triggers" {
  for_each          = toset(var.lambda_trigger_names)
  name              = "/aws/lambda/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Component = "cognito-lambda-trigger"
      Trigger   = each.value
    }
  )
}

resource "aws_cloudwatch_log_stream" "lambda_trigger_streams" {
  for_each       = toset(var.lambda_trigger_names)
  name           = "cognito-${var.user_pool_name}-stream"
  log_group_name = aws_cloudwatch_log_group.lambda_triggers[each.key].name
}

# --------------------------------------------------------------------------------------------------
# 4. AWS CloudTrail Audit Trail & CloudWatch Logs Routing for Cognito Events
# --------------------------------------------------------------------------------------------------
# S3 Audit Bucket for CloudTrail Logs
resource "aws_s3_bucket" "audit_bucket" {
  count         = var.enable_cloudtrail_logging && var.create_audit_bucket ? 1 : 0
  bucket        = local.cloudtrail_bucket_name
  force_destroy = var.audit_bucket_force_destroy

  tags = merge(
    local.common_tags,
    {
      Purpose = "cognito-cloudtrail-audit-storage"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "audit_bucket" {
  count  = var.enable_cloudtrail_logging && var.create_audit_bucket ? 1 : 0
  bucket = aws_s3_bucket.audit_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "audit_bucket" {
  count  = var.enable_cloudtrail_logging && var.create_audit_bucket ? 1 : 0
  bucket = aws_s3_bucket.audit_bucket[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_bucket" {
  count  = var.enable_cloudtrail_logging && var.create_audit_bucket ? 1 : 0
  bucket = aws_s3_bucket.audit_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "audit_bucket" {
  count  = var.enable_cloudtrail_logging && var.create_audit_bucket ? 1 : 0
  bucket = aws_s3_bucket.audit_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Policy for CloudTrail Delivery + Zero-Privilege TLS Enforcement
resource "aws_s3_bucket_policy" "audit_bucket" {
  count  = var.enable_cloudtrail_logging && var.create_audit_bucket ? 1 : 0
  bucket = aws_s3_bucket.audit_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceTLSRequestsOnly"
        Effect = "Deny"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.audit_bucket[0].arn,
          "${aws_s3_bucket.audit_bucket[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_bucket[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_bucket[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Dedicated CloudWatch Log Group for Cognito CloudTrail Events
resource "aws_cloudwatch_log_group" "cognito_cloudtrail" {
  count             = var.enable_cloudtrail_logging ? 1 : 0
  name              = "/aws/cloudtrail/cognito-${var.user_pool_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Component = "cognito-audit-cloudwatch"
    }
  )
}

# IAM Role for CloudTrail to send events to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudtrail_logging ? 1 : 0
  name  = "saayam-${var.environment}-cognito-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  count = var.enable_cloudtrail_logging ? 1 : 0
  name  = "saayam-${var.environment}-cloudtrail-cw-policy"
  role  = aws_iam_role.cloudtrail_to_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailPutLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cognito_cloudtrail[0].arn}:*"
      }
    ]
  })
}

# CloudTrail Trail for Cognito Events
resource "aws_cloudtrail" "cognito_trail" {
  count                         = var.enable_cloudtrail_logging ? 1 : 0
  name                          = "cognito-${var.user_pool_name}-audit-trail"
  s3_bucket_name                = var.create_audit_bucket ? aws_s3_bucket.audit_bucket[0].id : var.audit_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cognito_cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch[0].arn

  # Advanced event selectors for Cognito User Pool events
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Cognito::UserPool"
      values = [aws_cognito_user_pool.this.arn]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.audit_bucket
  ]

  tags = local.common_tags
}
