# --------------------------------------------------------------------------------------------------
# Module Variables: AWS Systems Manager (SSM) Parameter Store
# Description: Team-level hierarchical configuration storage with zero cost on Standard tier.
#              Enforces /{team-name}/{service-name}/{parameter} hierarchy.
# --------------------------------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Environment identifier (dev, qa, staging, prod)"
  default     = "dev"
}

variable "prefix_environment" {
  type        = bool
  description = "If true, prefixes parameters with environment: /{environment}/{team}/{service}/{param}. If false: /{team}/{service}/{param}"
  default     = false
}

variable "parameters" {
  type = map(object({
    team        = string
    service     = string
    type        = optional(string, "String")       # String, StringList, SecureString
    value       = string
    description = optional(string, "")
    tier        = optional(string, "Standard")     # Standard (free) or Advanced
    data_type   = optional(string, "text")
    overwrite   = optional(bool, true)
    kms_key_id  = optional(string, "")            # Blank defaults to alias/aws/ssm
    tags        = optional(map(string), {})
  }))
  description = "Map of parameters to provision under the team hierarchy /{team}/{service}/{param_key}"
  default     = {}
}

variable "create_kms_key" {
  type        = bool
  description = "Whether to create a dedicated customer managed KMS key for SecureString encryption (default false to use free alias/aws/ssm)"
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "Custom KMS key ARN to use for SecureString parameters when create_kms_key is false"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all Parameter Store resources"
  default     = {}
}
