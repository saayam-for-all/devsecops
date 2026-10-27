# --------------------------------------------------------------------------------------------------
# Input Variables: Hardened Regional Private S3 Bucket Module
# --------------------------------------------------------------------------------------------------

variable "bucket_name" {
  type        = string
  description = "Globally unique name for the S3 bucket"
}

variable "environment" {
  type        = string
  description = "Target deployment environment (e.g. dev, qa, stage, prod)"
  default     = "qa"
}

variable "force_destroy" {
  type        = bool
  description = "Whether to delete all objects upon bucket destruction (safe for test/dev)"
  default     = false
}

variable "enable_versioning" {
  type        = bool
  description = "Whether object versioning is enabled"
  default     = true
}

variable "sse_algorithm" {
  type        = string
  description = "Server-side encryption algorithm: AES256 or aws:kms"
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be either 'AES256' or 'aws:kms'."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "KMS master key ARN (used only when sse_algorithm is aws:kms)"
  default     = ""
}

variable "enable_lifecycle_rules" {
  type        = bool
  description = "Whether lifecycle rules are active"
  default     = true
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Number of days before noncurrent object versions expire (0 to disable)"
  default     = 90
}

variable "allowed_principal_arns" {
  type        = list(string)
  description = "List of IAM principal ARNs authorized to access the bucket (zero-privilege whitelist)"
  default     = []
}

variable "allowed_actions" {
  type        = list(string)
  description = "List of S3 actions allowed for authorized principals"
  default = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:ListBucket"
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags to attach to bucket resources"
  default     = {}
}
