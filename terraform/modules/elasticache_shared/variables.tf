# --------------------------------------------------------------------------------------------------
# Module Variables: Shared AWS ElastiCache Cluster (Valkey / Redis)
# Description: Configures the lowest-cost ElastiCache instance (cache.t4g.micro with Valkey engine)
#              with zero-privilege security groups and encryption.
# --------------------------------------------------------------------------------------------------

variable "name_prefix" {
  type        = string
  description = "Prefix for all resource names"
  default     = "saayam"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, qa, staging, prod)"
  default     = "dev"
}

variable "engine" {
  type        = string
  description = "Cache engine. Defaults to 'valkey' for absolute lowest cost (~33% cheaper than redis)"
  default     = "valkey"

  validation {
    condition     = contains(["valkey", "redis"], lower(var.engine))
    error_message = "Engine must be either 'valkey' or 'redis'."
  }
}

variable "engine_version" {
  type        = string
  description = "Engine version for the cluster (e.g., '7.2' for Valkey/Redis)"
  default     = "7.2"
}

variable "node_type" {
  type        = string
  description = "Compute and memory capacity node type. Default is cache.t4g.micro for lowest cost"
  default     = "cache.t4g.micro"
}

variable "port" {
  type        = number
  description = "Port number on which the cache nodes accept connections"
  default     = 6379
}

variable "num_cache_nodes" {
  type        = number
  description = "Number of cache nodes (1 for dev/standalone low cost; >1 for replication/failover)"
  default     = 1
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ElastiCache cluster and security group reside"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the ElastiCache subnet group"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs of microservices permitted to access ElastiCache on port 6379"
  default     = []
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "VPC or subnet CIDR blocks permitted to access ElastiCache on port 6379"
  default     = []
}

variable "parameter_group_family" {
  type        = string
  description = "Parameter group family. Defaults to 'valkey7' or 'redis7' depending on engine"
  default     = ""
}

variable "parameters" {
  type        = map(string)
  description = "Custom parameters to apply to the parameter group"
  default = {
    "maxmemory-policy" = "volatile-lru"
    "timeout"          = "300"
  }
}

variable "transit_encryption_enabled" {
  type        = bool
  description = "Enable TLS encryption in transit for all connections (zero-privilege best practice)"
  default     = true
}

variable "at_rest_encryption_enabled" {
  type        = bool
  description = "Enable encryption at rest on storage"
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "KMS Customer Managed Key ARN for at-rest encryption. If blank, default AWS KMS key is used"
  default     = ""
}

variable "auth_token" {
  type        = string
  description = "Optional AUTH password token (requires transit_encryption_enabled = true). Leave empty if using IAM auth or VPC isolation"
  default     = ""
  sensitive   = true
}

variable "automatic_failover_enabled" {
  type        = bool
  description = "Enable automatic failover. Must be false if num_cache_nodes is 1"
  default     = false
}

variable "multi_az_enabled" {
  type        = bool
  description = "Enable Multi-AZ deployment across availability zones (dev defaults to false for cost savings)"
  default     = false
}

variable "maintenance_window" {
  type        = string
  description = "Weekly time range for system maintenance in UTC"
  default     = "sun:03:00-sun:04:00"
}

variable "snapshot_retention_limit" {
  type        = number
  description = "Number of days for which automated snapshots are retained. 0 disables snapshots (lowest cost for dev)"
  default     = 0
}

variable "snapshot_window" {
  type        = string
  description = "Daily time range during which automated snapshots are created (UTC)"
  default     = "02:00-03:00"
}

variable "apply_immediately" {
  type        = bool
  description = "Apply changes immediately or during the next maintenance window"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to attach to all ElastiCache resources"
  default     = {}
}
