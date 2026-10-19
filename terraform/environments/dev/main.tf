# --------------------------------------------------------------------------------------------------
# Development Environment: Shared Infrastructure & Microservices Access
# Root configuration deploying:
#   1. Shared lowest-cost ElastiCache Cluster (Valkey on cache.t4g.micro)
#   2. Standardized Hierarchical SSM Parameter Store (/{team}/{service}/{param})
#   3. Microservice Least-Privilege IAM Roles & Policies (scoped to Virginia + Ireland)
#   4. Developer IAM Users & Assumable Roles
# --------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# VPC and Subnet lookup fallback if not explicitly provided
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

locals {
  resolved_vpc_id = var.vpc_id != "" ? var.vpc_id : (length(data.aws_vpc.default) > 0 ? data.aws_vpc.default[0].id : "")
}

data "aws_subnets" "default" {
  count = length(var.subnet_ids) == 0 && local.resolved_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.resolved_vpc_id]
  }
}

locals {
  resolved_subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (
    length(data.aws_subnets.default) > 0 ? data.aws_subnets.default[0].ids : []
  )

  # Merge dynamic cache endpoint into parameter store map
  all_ssm_parameters = merge(
    var.ssm_parameters,
    var.enable_shared_elasticache ? {
      "cache_endpoint" = {
        team        = "shared"
        service     = "infrastructure"
        type        = "String"
        value       = module.shared_elasticache[0].primary_endpoint_address
        description = "Primary endpoint address for shared ElastiCache (Valkey) cluster"
        tier        = "Standard"
      },
      "cache_port" = {
        team        = "shared"
        service     = "infrastructure"
        type        = "String"
        value       = tostring(module.shared_elasticache[0].port)
        description = "Port for shared ElastiCache cluster"
        tier        = "Standard"
      }
    } : {}
  )
}

# --------------------------------------------------------------------------------------------------
# 1. Shared ElastiCache (Valkey) Cluster
#    Lowest-cost option (cache.t4g.micro + Valkey engine with 33% discount)
# --------------------------------------------------------------------------------------------------
module "shared_elasticache" {
  count  = var.enable_shared_elasticache && length(local.resolved_subnet_ids) > 0 ? 1 : 0
  source = "../../modules/elasticache_shared"

  name_prefix     = "saayam"
  environment     = var.environment
  engine          = var.elasticache_engine
  engine_version  = var.elasticache_engine_version
  node_type       = var.elasticache_node_type
  num_cache_nodes = var.elasticache_num_nodes

  vpc_id              = local.resolved_vpc_id
  subnet_ids          = local.resolved_subnet_ids
  allowed_cidr_blocks = var.allowed_cidr_blocks

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Team        = "DevSecOps"
  }
}

# --------------------------------------------------------------------------------------------------
# 2. Standardized Systems Manager (SSM) Parameter Store
#    Hierarchical configuration: /{team-name}/{service-name}/{parameter}
# --------------------------------------------------------------------------------------------------
module "ssm_parameter_store" {
  count  = var.enable_ssm_parameter_store ? 1 : 0
  source = "../../modules/ssm_parameter_store"

  environment = var.environment
  parameters  = local.all_ssm_parameters

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Team        = "DevSecOps"
  }
}

# --------------------------------------------------------------------------------------------------
# 3. Microservice Least-Privilege IAM Roles & Policies (Virginia + Ireland Scoped)
# --------------------------------------------------------------------------------------------------

# Example A: Volunteer Microservice Role (Access to /volunteer/* and shared cache)
module "volunteer_microservice_iam" {
  source = "../../modules/microservice_access_iam"

  name_prefix  = "saayam"
  environment  = var.environment
  team_name    = "volunteer"
  service_name = "profile-service"
  regions      = var.target_regions

  elasticache_replication_group_ids = var.enable_shared_elasticache && length(module.shared_elasticache) > 0 ? [
    module.shared_elasticache[0].replication_group_id
  ] : []

  allow_shared_team_parameters = true

  trusted_service_principals = [
    "ecs-tasks.amazonaws.com",
    "lambda.amazonaws.com"
  ]

  tags = {
    Team    = "Volunteer-Backend"
    Service = "volunteer-profile-service"
  }
}

# Example B: Request Microservice Role (Access to /request/* and shared cache)
module "request_microservice_iam" {
  source = "../../modules/microservice_access_iam"

  name_prefix  = "saayam"
  environment  = var.environment
  team_name    = "request"
  service_name = "matching-service"
  regions      = var.target_regions

  elasticache_replication_group_ids = var.enable_shared_elasticache && length(module.shared_elasticache) > 0 ? [
    module.shared_elasticache[0].replication_group_id
  ] : []

  allow_shared_team_parameters = true

  trusted_service_principals = [
    "ecs-tasks.amazonaws.com",
    "lambda.amazonaws.com"
  ]

  tags = {
    Team    = "Request-Backend"
    Service = "request-matching-service"
  }
}

# --------------------------------------------------------------------------------------------------
# 4. Developer IAM User & Project Role Provisioning (Issue #75)
# --------------------------------------------------------------------------------------------------

module "volunteer_dev_user" {
  source = "../../modules/iam_dev_user_role"

  environment        = var.environment
  project_name       = "volunteer"
  developer_username = var.volunteer_developer_username
  developer_email    = var.volunteer_developer_email
  custom_role_name   = "VolunteerMicroServices-S3-ProfilePicUpload-${var.environment}"

  s3_bucket_arns            = var.volunteer_s3_bucket_arns
  s3_object_prefix_pattern  = "profile-pics/*"
  s3_allowed_actions = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:AbortMultipartUpload",
    "s3:ListMultipartUploadParts"
  ]

  store_in_secrets_manager     = true
  max_session_duration_seconds = 43200

  tags = {
    Team    = "Volunteer-Backend"
    Service = "volunteer-service"
  }
}

module "additional_dev_users" {
  for_each = var.additional_developers
  source   = "../../modules/iam_dev_user_role"

  environment        = var.environment
  project_name       = each.value.project_name
  developer_username = each.key
  developer_email    = lookup(each.value, "email", "")
  role_purpose       = lookup(each.value, "role_purpose", "dev-access")
  s3_bucket_arns     = lookup(each.value, "s3_bucket_arns", [])

  store_in_secrets_manager = true

  tags = {
    Team = lookup(each.value, "team", "DevSecOps")
  }
}
