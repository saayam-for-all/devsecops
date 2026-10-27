# --------------------------------------------------------------------------------------------------
# Input Variables: Dev Environment
# --------------------------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region for deployment (e.g., us-east-1 for Virginia, eu-west-1 for Ireland)"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

variable "target_regions" {
  type        = list(string)
  description = "Target deployment regions for multi-region microservice access policies"
  default     = ["us-east-1", "eu-west-1"]
}

# --------------------------------------------------------------------------------------------------
# Networking for Shared Services
# --------------------------------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "VPC ID where ElastiCache will be deployed (if empty, default VPC is queried)"
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ElastiCache subnet group (if empty, default VPC subnets are queried)"
  default     = []
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks permitted to access ElastiCache on port 6379"
  default     = ["10.0.0.0/16", "172.31.0.0/16"]
}

# --------------------------------------------------------------------------------------------------
# Shared ElastiCache (Valkey / Redis) Configuration
# --------------------------------------------------------------------------------------------------
variable "enable_shared_elasticache" {
  type        = bool
  description = "Whether to provision the shared ElastiCache cluster"
  default     = true
}

variable "elasticache_engine" {
  type        = string
  description = "ElastiCache engine. Defaults to 'valkey' for lowest cost (33% cheaper than redis)"
  default     = "valkey"
}

variable "elasticache_engine_version" {
  type        = string
  description = "Engine version for ElastiCache (e.g. 7.2)"
  default     = "7.2"
}

variable "elasticache_node_type" {
  type        = string
  description = "Node type for ElastiCache. Default is lowest cost cache.t4g.micro"
  default     = "cache.t4g.micro"
}

variable "elasticache_num_nodes" {
  type        = number
  description = "Number of cache nodes (1 for dev lowest cost)"
  default     = 1
}

# --------------------------------------------------------------------------------------------------
# SSM Parameter Store Configuration (Team Hierarchy)
# --------------------------------------------------------------------------------------------------
variable "enable_ssm_parameter_store" {
  type        = bool
  description = "Whether to provision standard hierarchical SSM parameters"
  default     = true
}

variable "ssm_parameters" {
  type = map(object({
    team        = string
    service     = string
    type        = optional(string, "String")
    value       = string
    description = optional(string, "")
    tier        = optional(string, "Standard")
  }))
  description = "Map of hierarchical parameters under /{team}/{service}/{param_key}"
  default = {
    "db_host" = {
      team        = "volunteer"
      service     = "profile-service"
      type        = "String"
      value       = "aurora-dev.saayam.internal"
      description = "Aurora database host for volunteer profile service"
    }
    "db_password" = {
      team        = "volunteer"
      service     = "profile-service"
      type        = "SecureString"
      value       = "DevSecretPassword123!"
      description = "Database master password for volunteer profile service"
    }
    "matching_api_url" = {
      team        = "request"
      service     = "matching-service"
      type        = "String"
      value       = "https://api-dev.saayam.org/matching"
      description = "Matching service API base URL"
    }
    "api_key" = {
      team        = "request"
      service     = "matching-service"
      type        = "SecureString"
      value       = "DevRequestServiceApiKey123!"
      description = "Service-level API key for request matching service"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Developer IAM Onboarding (Issue #75)
# --------------------------------------------------------------------------------------------------
variable "volunteer_developer_username" {
  type        = string
  description = "Developer username for the Volunteer Microservices setup"
  default     = "volunteer-dev"
}

variable "volunteer_developer_email" {
  type        = string
  description = "Developer email for Volunteer setup notifications"
  default     = "volunteer-dev@saayam.org"
}

variable "volunteer_s3_bucket_arns" {
  type        = list(string)
  description = "ARNs of S3 buckets for the Volunteer service profile pictures"
  default = [
    "arn:aws:s3:::saayam-dev-volunteer-media",
    "arn:aws:s3:::saayam-virginia-private"
  ]
}

variable "additional_developers" {
  type = map(object({
    project_name   = string
    email          = optional(string, "")
    role_purpose   = optional(string, "dev-access")
    team           = optional(string, "Backend")
    s3_bucket_arns = optional(list(string), [])
  }))
  description = "Map of additional developers to provision modularly"
  default     = {}
}

# --------------------------------------------------------------------------------------------------
# Cognito User Pool & Private S3 Hardening (Issue #65)
# --------------------------------------------------------------------------------------------------
variable "enable_cognito_user_pool" {
  type        = bool
  description = "Whether to provision the DevUserPool in the dev environment"
  default     = true
}

variable "dev_user_pool_name" {
  type        = string
  description = "Name of the Dev Cognito User Pool"
  default     = "DevUserPool"
}

variable "enable_dev_private_bucket" {
  type        = bool
  description = "Whether to provision the regional dev-private S3 bucket"
  default     = true
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix for private S3 buckets (default empty for literal name)"
  default     = ""
}

