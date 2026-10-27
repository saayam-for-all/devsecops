# --------------------------------------------------------------------------------------------------
# QA Environment: QA Cognito User Pool, Hardened S3 Buckets & Netlify SSM Parameters
# Issue #65: "Create QAUserPool in Cognito replicating the DevUserPool (without users) to implement
#             and test Cognito Advanced Security Features"
# --------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_prefix = var.bucket_prefix != "" ? "${var.bucket_prefix}-" : ""
}

# --------------------------------------------------------------------------------------------------
# 1. QA Cognito User Pool (QAUserPool) with Advanced Security & CloudTrail/CloudWatch
# --------------------------------------------------------------------------------------------------
module "qa_cognito_user_pool" {
  source = "../../modules/cognito_user_pool"

  environment            = var.environment
  user_pool_name         = var.user_pool_name
  advanced_security_mode = var.advanced_security_mode
  mfa_configuration      = var.mfa_configuration

  # Netlify Web App App Client
  client_name          = var.app_client_name
  client_callback_urls = var.callback_urls
  client_logout_urls   = var.logout_urls

  # CloudWatch Log Streams for attached Lambda triggers
  lambda_trigger_names = var.lambda_trigger_names

  # CloudTrail Cognito event routing
  enable_cloudtrail_logging = true
  log_retention_days        = 90

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Team        = "DevSecOps"
    Purpose     = "QA-Authentication-AdvancedSecurity"
  }
}

# --------------------------------------------------------------------------------------------------
# 2. Hardened Regional Private S3 Buckets (Public Access Blocked, Zero-Privilege)
# --------------------------------------------------------------------------------------------------
module "qa_private_virginia" {
  count  = var.enable_private_s3_buckets && data.aws_region.current.name == "us-east-1" ? 1 : 0
  source = "../../modules/s3_private_bucket"

  bucket_name   = "${local.bucket_prefix}qa-private-virginia"
  environment   = var.environment
  sse_algorithm = var.sse_algorithm

  enable_versioning      = true
  enable_lifecycle_rules = true

  tags = {
    Region = "us-east-1"
    Scope  = "QA-Private-Storage"
  }
}

module "qa_private_ireland" {
  count  = var.enable_private_s3_buckets && data.aws_region.current.name == "eu-west-1" ? 1 : 0
  source = "../../modules/s3_private_bucket"

  bucket_name   = "${local.bucket_prefix}qa-private-ireland"
  environment   = var.environment
  sse_algorithm = var.sse_algorithm

  enable_versioning      = true
  enable_lifecycle_rules = true

  tags = {
    Region = "eu-west-1"
    Scope  = "QA-Private-Storage"
  }
}

# --------------------------------------------------------------------------------------------------
# 3. Netlify Webapp Parameters exported to SSM Parameter Store (/saayam/qa/cognito/*)
# --------------------------------------------------------------------------------------------------
locals {
  netlify_ssm_parameters = {
    "cognito/user_pool_id" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool.user_pool_id
      description = "QA Cognito User Pool ID for Netlify Webapp"
    },
    "cognito/user_pool_arn" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool.user_pool_arn
      description = "QA Cognito User Pool ARN"
    },
    "cognito/app_client_id" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool.primary_client_id
      description = "QA Cognito App Client ID for QA_saayam-netlify.app"
    },
    "cognito/client_id" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool.primary_client_id
      description = "Alias for Cognito Client ID"
    },
    "cognito/region" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = data.aws_region.current.name
      description = "AWS Region hosting the QA Cognito User Pool"
    },
    "cognito/redirect_uri" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = "https://QA_saayam-netlify.app/callback"
      description = "OAuth redirect URI for QA Netlify Webapp"
    },
    "cognito/logout_uri" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = "https://QA_saayam-netlify.app/logout"
      description = "OAuth sign-out URI for QA Netlify Webapp"
    },
    "cognito/app_url" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = "https://QA_saayam-netlify.app"
      description = "Netlify QA Webapp base URL"
    },
    "cognito/authority" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${module.qa_cognito_user_pool.user_pool_id}"
      description = "OIDC Issuer Authority URL for QA User Pool"
    },
    "cognito/advanced_security_mode" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool.advanced_security_mode
      description = "Cognito Advanced Security Features mode"
    }
  }
}

module "ssm_parameter_store" {
  count  = var.enable_ssm_parameter_store ? 1 : 0
  source = "../../modules/ssm_parameter_store"

  environment        = var.environment
  prefix_environment = false # Preserves /saayam/qa/cognito/*
  parameters         = merge(local.netlify_ssm_parameters, var.extra_ssm_parameters)

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Team        = "DevSecOps"
  }
}
