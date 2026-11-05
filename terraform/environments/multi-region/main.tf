# --------------------------------------------------------------------------------------------------
# Multi-Region Environment: Virginia (us-east-1) & Ireland (eu-west-1)
# Demonstrates unified dual-region deployment of shared ElastiCache (Valkey) and SSM Parameter Store
# --------------------------------------------------------------------------------------------------

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

module "ssm_virginia" {
  source    = "../../modules/ssm_parameter_store"
  providers = { aws = aws.virginia }

  environment = var.environment
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
    }
  )

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

module "ssm_ireland" {
  source    = "../../modules/ssm_parameter_store"
  providers = { aws = aws.ireland }

  environment = var.environment
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
