# --------------------------------------------------------------------------------------------------
# Multi-Region Environment Variables (Virginia us-east-1 + Ireland eu-west-1)
# --------------------------------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "multi-region"
}

# Virginia Networking
variable "virginia_vpc_id" {
  type        = string
  description = "VPC ID in us-east-1"
  default     = ""
}

variable "virginia_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs in us-east-1"
  default     = []
}

# Ireland Networking
variable "ireland_vpc_id" {
  type        = string
  description = "VPC ID in eu-west-1"
  default     = ""
}

variable "ireland_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs in eu-west-1"
  default     = []
}

# ElastiCache Shared Config
variable "elasticache_engine" {
  type        = string
  description = "Cache engine (defaults to 'valkey' for lowest cost)"
  default     = "valkey"
}

variable "elasticache_engine_version" {
  type        = string
  description = "Engine version"
  default     = "7.2"
}

variable "elasticache_node_type" {
  type        = string
  description = "Node type (defaults to cache.t4g.micro for lowest cost)"
  default     = "cache.t4g.micro"
}

# Team Parameters for Parameter Store
variable "common_parameters" {
  type = map(object({
    team        = string
    service     = string
    type        = optional(string, "String")
    value       = string
    description = optional(string, "")
  }))
  description = "Parameters to replicate in both Virginia and Ireland Parameter Stores"
  default = {
    "volunteer_db_host" = {
      team        = "volunteer"
      service     = "profile-service"
      type        = "String"
      value       = "aurora.saayam.internal"
      description = "Database host"
    }
    "request_api_key" = {
      team        = "request"
      service     = "matching-service"
      type        = "SecureString"
      value       = "ChangeMeDevSecret123!"
      description = "Request API Key"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Regional Private S3 Buckets (Issue #65)
# --------------------------------------------------------------------------------------------------
variable "enable_regional_private_s3_buckets" {
  type        = bool
  description = "Whether to provision the 8 regional private S3 buckets across Virginia and Ireland"
  default     = true
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix for private S3 buckets (default empty for literal bucket names)"
  default     = ""
}

variable "s3_sse_algorithm" {
  type        = string
  description = "S3 server-side encryption algorithm: AES256 or aws:kms"
  default     = "AES256"
}

# --------------------------------------------------------------------------------------------------
# Cognito User Pools: DevUserPool & QAUserPool (Issue #65)
# --------------------------------------------------------------------------------------------------
variable "enable_cognito_user_pools" {
  type        = bool
  description = "Whether to provision DevUserPool and QAUserPool"
  default     = true
}

variable "qa_advanced_security_mode" {
  type        = string
  description = "Cognito Advanced Security Features mode for QAUserPool (ENFORCED or AUDIT)"
  default     = "ENFORCED"
}

variable "qa_callback_urls" {
  type        = list(string)
  description = "Allowed callback URLs for QA_saayam-netlify.app"
  default = [
    "https://QA_saayam-netlify.app/callback",
    "https://QA_saayam-netlify.app",
    "http://localhost:3000/callback"
  ]
}

variable "qa_logout_urls" {
  type        = list(string)
  description = "Allowed logout URLs for QA_saayam-netlify.app"
  default = [
    "https://QA_saayam-netlify.app/logout",
    "http://localhost:3000/logout"
  ]
}

variable "qa_lambda_trigger_names" {
  type        = list(string)
  description = "Cognito Lambda trigger function names to provision CloudWatch log streams for"
  default = [
    "saayam-qa-cognito-pre-sign-up",
    "saayam-qa-cognito-post-confirmation"
  ]
}
