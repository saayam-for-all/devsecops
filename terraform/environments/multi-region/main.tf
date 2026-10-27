# --------------------------------------------------------------------------------------------------
# Multi-Region Environment: Virginia (us-east-1) & Ireland (eu-west-1)
# Demonstrates unified dual-region deployment of:
#   1. Shared ElastiCache (Valkey) and SSM Parameter Store
#   2. Regional Hardened Private S3 Buckets across Virginia and Ireland (Issue #65)
#   3. DevUserPool & QAUserPool with Cognito Advanced Security Features & Audit Logging (Issue #65)
#   4. Netlify QA Webapp SSM Parameter Store Exports under /saayam/qa/cognito/* (Issue #65)
#   5. Scoped Microservice Access IAM Roles
# --------------------------------------------------------------------------------------------------

locals {
  bucket_prefix = var.bucket_prefix != "" ? "${var.bucket_prefix}-" : ""
}

# --------------------------------------------------------------------------------------------------
# Virginia (us-east-1) Data Lookups & Shared Services
# --------------------------------------------------------------------------------------------------
data "aws_vpc" "virginia_default" {
  provider = aws.virginia
  count    = var.virginia_vpc_id == "" ? 1 : 0
  default  = true
}

locals {
  virginia_vpc_id = var.virginia_vpc_id != "" ? var.virginia_vpc_id : (
    length(data.aws_vpc.virginia_default) > 0 ? data.aws_vpc.virginia_default[0].id : ""
  )
}

data "aws_subnets" "virginia_default" {
  provider = aws.virginia
  count    = length(var.virginia_subnet_ids) == 0 && local.virginia_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.virginia_vpc_id]
  }
}

locals {
  virginia_subnet_ids = length(var.virginia_subnet_ids) > 0 ? var.virginia_subnet_ids : (
    length(data.aws_subnets.virginia_default) > 0 ? data.aws_subnets.virginia_default[0].ids : []
  )
}

module "elasticache_virginia" {
  source    = "../../modules/elasticache_shared"
  providers = { aws = aws.virginia }

  name_prefix     = "saayam-va"
  environment     = var.environment
  engine          = var.elasticache_engine
  engine_version  = var.elasticache_engine_version
  node_type       = var.elasticache_node_type
  num_cache_nodes = 1

  vpc_id              = local.virginia_vpc_id
  subnet_ids          = local.virginia_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16", "172.31.0.0/16"]

  tags = {
    Region = "us-east-1"
  }
}

# --------------------------------------------------------------------------------------------------
# Ireland (eu-west-1) Data Lookups & Shared Services
# --------------------------------------------------------------------------------------------------
data "aws_vpc" "ireland_default" {
  provider = aws.ireland
  count    = var.ireland_vpc_id == "" ? 1 : 0
  default  = true
}

locals {
  ireland_vpc_id = var.ireland_vpc_id != "" ? var.ireland_vpc_id : (
    length(data.aws_vpc.ireland_default) > 0 ? data.aws_vpc.ireland_default[0].id : ""
  )
}

data "aws_subnets" "ireland_default" {
  provider = aws.ireland
  count    = length(var.ireland_subnet_ids) == 0 && local.ireland_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.ireland_vpc_id]
  }
}

locals {
  ireland_subnet_ids = length(var.ireland_subnet_ids) > 0 ? var.ireland_subnet_ids : (
    length(data.aws_subnets.ireland_default) > 0 ? data.aws_subnets.ireland_default[0].ids : []
  )
}

module "elasticache_ireland" {
  source    = "../../modules/elasticache_shared"
  providers = { aws = aws.ireland }

  name_prefix     = "saayam-irl"
  environment     = var.environment
  engine          = var.elasticache_engine
  engine_version  = var.elasticache_engine_version
  node_type       = var.elasticache_node_type
  num_cache_nodes = 1

  vpc_id              = local.ireland_vpc_id
  subnet_ids          = local.ireland_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16", "172.31.0.0/16"]

  tags = {
    Region = "eu-west-1"
  }
}

# --------------------------------------------------------------------------------------------------
# Regional Hardened Private S3 Buckets across Virginia (us-east-1) & Ireland (eu-west-1)
# Zero public access, SSE-S3 AES256, versioned, zero-privilege IAM policies
# --------------------------------------------------------------------------------------------------

# 1. Virginia Regional Private S3 Buckets
module "dev_private_virginia" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.virginia }

  bucket_name   = "${local.bucket_prefix}dev-private-virginia"
  environment   = "dev"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "dev"
    Region      = "us-east-1"
    Inventory   = "dev-private-virginia"
  }
}

module "qa_private_virginia" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.virginia }

  bucket_name   = "${local.bucket_prefix}qa-private-virginia"
  environment   = "qa"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "qa"
    Region      = "us-east-1"
    Inventory   = "qa-private-virginia"
  }
}

module "stage_private_virginia" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.virginia }

  bucket_name   = "${local.bucket_prefix}stage-private-virginia"
  environment   = "stage"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "stage"
    Region      = "us-east-1"
    Inventory   = "stage-private-virginia"
  }
}

module "prod_private_virginia" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.virginia }

  bucket_name   = "${local.bucket_prefix}prod-private-virginia"
  environment   = "prod"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "prod"
    Region      = "us-east-1"
    Inventory   = "prod-private-virginia"
  }
}

# 2. Ireland Regional Private S3 Buckets
module "dev_private_ireland" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.ireland }

  bucket_name   = "${local.bucket_prefix}dev-private-ireland"
  environment   = "dev"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "dev"
    Region      = "eu-west-1"
    Inventory   = "dev-private-ireland"
  }
}

module "qa_private_ireland" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.ireland }

  bucket_name   = "${local.bucket_prefix}qa-private-ireland"
  environment   = "qa"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "qa"
    Region      = "eu-west-1"
    Inventory   = "qa-private-ireland"
  }
}

module "stage_private_ireland" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.ireland }

  bucket_name   = "${local.bucket_prefix}stage-private-ireland"
  environment   = "stage"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "stage"
    Region      = "eu-west-1"
    Inventory   = "stage-private-ireland"
  }
}

module "prod_private_ireland" {
  count     = var.enable_regional_private_s3_buckets ? 1 : 0
  source    = "../../modules/s3_private_bucket"
  providers = { aws = aws.ireland }

  bucket_name   = "${local.bucket_prefix}prod-private-ireland"
  environment   = "prod"
  sse_algorithm = var.s3_sse_algorithm

  tags = {
    Environment = "prod"
    Region      = "eu-west-1"
    Inventory   = "prod-private-ireland"
  }
}

# --------------------------------------------------------------------------------------------------
# Cognito User Pools: DevUserPool & QAUserPool Replication (Issue #65)
# --------------------------------------------------------------------------------------------------

# Baseline DevUserPool
module "dev_cognito_user_pool" {
  count     = var.enable_cognito_user_pools ? 1 : 0
  source    = "../../modules/cognito_user_pool"
  providers = { aws = aws.virginia }

  environment            = "dev"
  user_pool_name         = "DevUserPool"
  advanced_security_mode = "OFF"
  mfa_configuration      = "OPTIONAL"

  client_name = "saayam-dev-webapp-client"
  client_callback_urls = [
    "http://localhost:3000/callback",
    "https://dev.saayam.org/callback"
  ]
  client_logout_urls = [
    "http://localhost:3000/logout",
    "https://dev.saayam.org/logout"
  ]

  enable_cloudtrail_logging = false

  tags = {
    Environment = "dev"
    Pool        = "DevUserPool"
  }
}

# Replicated QAUserPool with Advanced Security Features & Audit Logging
module "qa_cognito_user_pool" {
  count     = var.enable_cognito_user_pools ? 1 : 0
  source    = "../../modules/cognito_user_pool"
  providers = { aws = aws.virginia }

  environment            = "qa"
  user_pool_name         = "QAUserPool"
  advanced_security_mode = var.qa_advanced_security_mode
  mfa_configuration      = "OPTIONAL"

  # Netlify Web App Client
  client_name          = "saayam-qa-webapp-client"
  client_callback_urls = var.qa_callback_urls
  client_logout_urls   = var.qa_logout_urls

  # CloudWatch Log Streams for attached Lambda triggers
  lambda_trigger_names = var.qa_lambda_trigger_names

  # CloudTrail audit logging routed to S3 + CloudWatch
  enable_cloudtrail_logging = true
  log_retention_days        = 90

  tags = {
    Environment = "qa"
    Pool        = "QAUserPool"
    Issue       = "65"
  }
}

# --------------------------------------------------------------------------------------------------
# Netlify Webapp Parameters exported to SSM Parameter Store (/saayam/qa/cognito/*)
# --------------------------------------------------------------------------------------------------
locals {
  qa_cognito_ssm_parameters = var.enable_cognito_user_pools ? {
    "cognito/user_pool_id" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool[0].user_pool_id
      description = "QA Cognito User Pool ID for QA_saayam-netlify.app"
    },
    "cognito/user_pool_arn" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool[0].user_pool_arn
      description = "QA Cognito User Pool ARN"
    },
    "cognito/app_client_id" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool[0].primary_client_id
      description = "QA Cognito App Client ID for QA_saayam-netlify.app"
    },
    "cognito/client_id" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool[0].primary_client_id
      description = "Alias for Cognito Client ID"
    },
    "cognito/region" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = "us-east-1"
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
      value       = "https://cognito-idp.us-east-1.amazonaws.com/${module.qa_cognito_user_pool[0].user_pool_id}"
      description = "OIDC Issuer Authority URL for QA User Pool"
    },
    "cognito/advanced_security_mode" = {
      team        = "saayam"
      service     = "qa"
      type        = "String"
      value       = module.qa_cognito_user_pool[0].advanced_security_mode
      description = "Cognito Advanced Security Features mode"
    }
  } : {}
}

module "ssm_virginia" {
  source    = "../../modules/ssm_parameter_store"
  providers = { aws = aws.virginia }

  environment        = var.environment
  prefix_environment = false
  parameters = merge(
    var.common_parameters,
    {
      "cache_endpoint" = {
        team        = "shared"
        service     = "infrastructure"
        type        = "String"
        value       = module.elasticache_virginia.primary_endpoint_address
        description = "Virginia Valkey endpoint"
      }
    },
    local.qa_cognito_ssm_parameters
  )

  tags = {
    Region = "us-east-1"
  }
}

module "ssm_ireland" {
  source    = "../../modules/ssm_parameter_store"
  providers = { aws = aws.ireland }

  environment        = var.environment
  prefix_environment = false
  parameters = merge(
    var.common_parameters,
    {
      "cache_endpoint" = {
        team        = "shared"
        service     = "infrastructure"
        type        = "String"
        value       = module.elasticache_ireland.primary_endpoint_address
        description = "Ireland Valkey endpoint"
      }
    }
  )

  tags = {
    Region = "eu-west-1"
  }
}

# --------------------------------------------------------------------------------------------------
# Multi-Region IAM Roles & Policies (Global IAM with Virginia + Ireland ARNs)
# --------------------------------------------------------------------------------------------------
module "volunteer_microservice_iam" {
  source = "../../modules/microservice_access_iam"

  environment  = var.environment
  team_name    = "volunteer"
  service_name = "profile-service"
  regions      = ["us-east-1", "eu-west-1"]

  elasticache_replication_group_ids = [
    module.elasticache_virginia.replication_group_id,
    module.elasticache_ireland.replication_group_id
  ]

  allow_shared_team_parameters = true

  trusted_service_principals = [
    "ecs-tasks.amazonaws.com",
    "lambda.amazonaws.com"
  ]

  tags = {
    Team = "Volunteer-Backend"
  }
}

module "request_microservice_iam" {
  source = "../../modules/microservice_access_iam"

  environment  = var.environment
  team_name    = "request"
  service_name = "matching-service"
  regions      = ["us-east-1", "eu-west-1"]

  elasticache_replication_group_ids = [
    module.elasticache_virginia.replication_group_id,
    module.elasticache_ireland.replication_group_id
  ]

  allow_shared_team_parameters = true

  trusted_service_principals = [
    "ecs-tasks.amazonaws.com",
    "lambda.amazonaws.com"
  ]

  tags = {
    Team = "Request-Backend"
  }
}
