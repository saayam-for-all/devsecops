# --------------------------------------------------------------------------------------------------
# Input Variables: QA Environment (Issue #65)
# --------------------------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "Primary AWS region for QA deployment (us-east-1 for Virginia, eu-west-1 for Ireland)"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "qa"
}

# --------------------------------------------------------------------------------------------------
# Cognito User Pool (QAUserPool)
# --------------------------------------------------------------------------------------------------
variable "user_pool_name" {
  type        = string
  description = "Name of the QA Cognito User Pool"
  default     = "QAUserPool"
}

variable "advanced_security_mode" {
  type        = string
  description = "Cognito Advanced Security Features mode (ENFORCED, AUDIT, or OFF)"
  default     = "ENFORCED"
}

variable "mfa_configuration" {
  type        = string
  description = "MFA configuration mode (OFF, ON, or OPTIONAL)"
  default     = "OPTIONAL"
}

variable "app_client_name" {
  type        = string
  description = "Name of the Netlify app client"
  default     = "saayam-qa-webapp-client"
}

variable "callback_urls" {
  type        = list(string)
  description = "Allowed redirect callback URLs for Netlify QA webapp"
  default = [
    "https://QA_saayam-netlify.app/callback",
    "https://QA_saayam-netlify.app",
    "http://localhost:3000/callback"
  ]
}

variable "logout_urls" {
  type        = list(string)
  description = "Allowed sign-out URLs for Netlify QA webapp"
  default = [
    "https://QA_saayam-netlify.app/logout",
    "http://localhost:3000/logout"
  ]
}

variable "lambda_trigger_names" {
  type        = list(string)
  description = "Attached Cognito Lambda triggers to provision CloudWatch log streams for"
  default = [
    "saayam-qa-cognito-pre-sign-up",
    "saayam-qa-cognito-post-confirmation"
  ]
}

# --------------------------------------------------------------------------------------------------
# Regional S3 Buckets Configuration
# --------------------------------------------------------------------------------------------------
variable "enable_private_s3_buckets" {
  type        = bool
  description = "Whether to provision the regional hardened private S3 buckets"
  default     = true
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix prepended to regional bucket names (set to empty string for literal names)"
  default     = ""
}

variable "sse_algorithm" {
  type        = string
  description = "S3 server-side encryption algorithm (AES256 or aws:kms)"
  default     = "AES256"
}

# --------------------------------------------------------------------------------------------------
# SSM Parameter Store
# --------------------------------------------------------------------------------------------------
variable "enable_ssm_parameter_store" {
  type        = bool
  description = "Whether to export Netlify Cognito parameters into SSM Parameter Store"
  default     = true
}

variable "extra_ssm_parameters" {
  type = map(object({
    team        = string
    service     = string
    type        = optional(string, "String")
    value       = string
    description = optional(string, "")
    tier        = optional(string, "Standard")
  }))
  description = "Additional SSM parameters to export under the team hierarchy"
  default     = {}
}
