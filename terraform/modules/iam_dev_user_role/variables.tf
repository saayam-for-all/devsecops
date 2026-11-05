# --------------------------------------------------------------------------------------------------
# Input Variables: Standardized IAM Developer User & Project Role Setup
# --------------------------------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Target deployment environment (e.g. dev, qa, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, staging, prod."
  }
}

variable "project_name" {
  type        = string
  description = "Project or microservice name (e.g. volunteer, request, notification, capa)"
}

variable "developer_username" {
  type        = string
  description = "Developer unique username (e.g. jdoe, sanjay-k, volunteer-dev-1)"
}

variable "developer_email" {
  type        = string
  description = "Developer contact email for tracking and notifications"
  default     = ""
}

variable "role_purpose" {
  type        = string
  description = "Descriptive role purpose suffix (e.g. s3-upload, db-read, lambda-dev)"
  default     = "s3-upload"
}

variable "custom_role_name" {
  type        = string
  description = "Optional explicit custom role name override (e.g. VolunteerMicroServices-S3-ProfilePicUpload)"
  default     = ""
}

variable "create_access_key" {
  type        = bool
  description = "Whether to create a programmatic IAM Access Key pair"
  default     = true
}

variable "store_in_secrets_manager" {
  type        = bool
  description = "Whether to securely store access keys and metadata in AWS Secrets Manager"
  default     = true
}

variable "secret_recovery_window_days" {
  type        = number
  description = "Number of days that AWS Secrets Manager waits before deleting a secret"
  default     = 0
}

variable "kms_key_id" {
  type        = string
  description = "Optional KMS Key ID/ARN for Secrets Manager encryption. If omitted, default AWS KMS key is used."
  default     = ""
}

variable "max_session_duration_seconds" {
  type        = number
  description = "Maximum session duration in seconds for assuming the project role (default: 12 hours = 43200s)"
  default     = 43200

  validation {
    condition     = var.max_session_duration_seconds >= 3600 && var.max_session_duration_seconds <= 43200
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "s3_bucket_arns" {
  type        = list(string)
  description = "List of S3 bucket ARNs the project role is granted scoped access to"
  default     = []
}

variable "s3_object_prefix_pattern" {
  type        = string
  description = "Object prefix pattern within target S3 buckets (e.g. 'profile-pics/*' or '*')"
  default     = "*"
}

variable "s3_allowed_actions" {
  type        = list(string)
  description = "List of allowed S3 object actions for the scoped project role"
  default = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:DeleteObject",
    "s3:AbortMultipartUpload",
    "s3:ListMultipartUploadParts"
  ]
}

variable "additional_policy_arns" {
  type        = list(string)
  description = "List of existing AWS managed or custom IAM policy ARNs to attach to the project role"
  default     = []
}

variable "allowed_ip_cidrs" {
  type        = list(string)
  description = "Optional list of IP CIDRs allowed to assume the role (leave empty for unconstrained)"
  default     = []
}

variable "force_destroy_user" {
  type        = bool
  description = "When destroying this user, destroy even if it has non-Terraform-managed IAM access keys or policies"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources created by this module"
  default     = {}
}
