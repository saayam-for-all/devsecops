# --------------------------------------------------------------------------------------------------
# Multi-Region Environment Variables (Virginia us-east-1 + Ireland eu-west-1)
# --------------------------------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
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
