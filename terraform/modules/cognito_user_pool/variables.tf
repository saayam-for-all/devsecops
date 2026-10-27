# --------------------------------------------------------------------------------------------------
# Input Variables: AWS Cognito User Pool Module
# --------------------------------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Environment identifier (e.g. dev, qa, staging, prod)"
  default     = "qa"
}

variable "user_pool_name" {
  type        = string
  description = "Name of the Cognito User Pool (e.g. QAUserPool or DevUserPool)"
  default     = "QAUserPool"
}

variable "deletion_protection" {
  type        = string
  description = "Whether deletion protection is enabled (ACTIVE or INACTIVE)"
  default     = "INACTIVE"
}

variable "advanced_security_mode" {
  type        = string
  description = "Cognito Advanced Security Features mode: ENFORCED, AUDIT, or OFF"
  default     = "ENFORCED"

  validation {
    condition     = contains(["ENFORCED", "AUDIT", "OFF"], var.advanced_security_mode)
    error_message = "advanced_security_mode must be one of: 'ENFORCED', 'AUDIT', 'OFF'."
  }
}

variable "mfa_configuration" {
  type        = string
  description = "MFA configuration for the user pool: OFF, ON, or OPTIONAL"
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be one of: 'OFF', 'ON', 'OPTIONAL'."
  }
}

variable "enable_software_token_mfa" {
  type        = bool
  description = "Whether software token MFA (TOTP) is enabled"
  default     = true
}

# --------------------------------------------------------------------------------------------------
# Password Policy Variables
# --------------------------------------------------------------------------------------------------
variable "password_minimum_length" {
  type        = number
  description = "Minimum length of the password"
  default     = 8
}

variable "password_require_lowercase" {
  type        = bool
  description = "Whether passwords require lowercase characters"
  default     = true
}

variable "password_require_uppercase" {
  type        = bool
  description = "Whether passwords require uppercase characters"
  default     = true
}

variable "password_require_numbers" {
  type        = bool
  description = "Whether passwords require numerical digits"
  default     = true
}

variable "password_require_symbols" {
  type        = bool
  description = "Whether passwords require special symbols"
  default     = true
}

variable "temporary_password_validity_days" {
  type        = number
  description = "Validity duration in days for temporary passwords"
  default     = 7
}

# --------------------------------------------------------------------------------------------------
# Registration & Verification
# --------------------------------------------------------------------------------------------------
variable "allow_admin_create_user_only" {
  type        = bool
  description = "If true, only administrators can create users. If false, users can self-register."
  default     = false
}

variable "email_verification_subject" {
  type        = string
  description = "Email verification subject line"
  default     = "Saayam Verification Code"
}

variable "email_verification_message" {
  type        = string
  description = "Email verification message template containing {####}"
  default     = "Your verification code for Saayam is {####}."
}

variable "email_sending_account" {
  type        = string
  description = "Email sending account type (COGNITO_DEFAULT or DEVELOPER)"
  default     = "COGNITO_DEFAULT"
}

# --------------------------------------------------------------------------------------------------
# Schema Customization
# --------------------------------------------------------------------------------------------------
variable "additional_custom_attributes" {
  type = list(object({
    name                = string
    attribute_data_type = optional(string, "String")
    mutable             = optional(bool, true)
    required            = optional(bool, false)
    min_length          = optional(number, 0)
    max_length          = optional(number, 256)
  }))
  description = "Additional custom attributes to append beyond the baseline schema"
  default     = []
}

# --------------------------------------------------------------------------------------------------
# Attached Lambda Triggers
# --------------------------------------------------------------------------------------------------
variable "lambda_triggers" {
  type        = map(string)
  description = "Map of Lambda trigger ARNs (pre_sign_up, post_confirmation, pre_authentication, etc.)"
  default     = {}
}

variable "lambda_trigger_names" {
  type        = list(string)
  description = "List of Lambda function names to create CloudWatch log groups and streams for"
  default     = []
}

# --------------------------------------------------------------------------------------------------
# Primary App Client (Netlify Web App)
# --------------------------------------------------------------------------------------------------
variable "client_name" {
  type        = string
  description = "Name of the primary app client"
  default     = "saayam-qa-webapp-client"
}

variable "client_generate_secret" {
  type        = bool
  description = "Whether to generate a client secret (false for browser SPAs / Netlify)"
  default     = false
}

variable "client_explicit_auth_flows" {
  type        = list(string)
  description = "Explicit authentication flows allowed on the app client"
  default = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]
}

variable "client_supported_identity_providers" {
  type        = list(string)
  description = "Supported identity providers for the app client"
  default     = ["COGNITO"]
}

variable "client_callback_urls" {
  type        = list(string)
  description = "Allowed callback URLs for OAuth redirects (e.g. QA_saayam-netlify.app)"
  default = [
    "https://QA_saayam-netlify.app/callback",
    "https://QA_saayam-netlify.app",
    "http://localhost:3000/callback"
  ]
}

variable "client_logout_urls" {
  type        = list(string)
  description = "Allowed logout URLs for OAuth redirects"
  default = [
    "https://QA_saayam-netlify.app/logout",
    "http://localhost:3000/logout"
  ]
}

variable "client_allowed_oauth_flows" {
  type        = list(string)
  description = "Allowed OAuth flows"
  default     = ["code", "implicit"]
}

variable "client_allowed_oauth_scopes" {
  type        = list(string)
  description = "Allowed OAuth scopes"
  default = [
    "email",
    "openid",
    "phone",
    "profile",
    "aws.cognito.signin.user.admin"
  ]
}

variable "client_allowed_oauth_flows_user_pool_client" {
  type        = bool
  description = "Whether client is allowed to follow OAuth protocol flows"
  default     = true
}

variable "access_token_validity" {
  type        = number
  description = "Access token validity in minutes"
  default     = 60
}

variable "id_token_validity" {
  type        = number
  description = "ID token validity in minutes"
  default     = 60
}

variable "refresh_token_validity" {
  type        = number
  description = "Refresh token validity in days"
  default     = 30
}

variable "additional_app_clients" {
  type        = any
  description = "Map of additional app clients to provision"
  default     = {}
}

variable "domain_prefix" {
  type        = string
  description = "Cognito hosted UI domain prefix (optional)"
  default     = ""
}

# --------------------------------------------------------------------------------------------------
# Audit Logging (CloudTrail & CloudWatch)
# --------------------------------------------------------------------------------------------------
variable "enable_cloudtrail_logging" {
  type        = bool
  description = "Whether to configure CloudTrail audit logging routed to S3 and CloudWatch Logs"
  default     = true
}

variable "create_audit_bucket" {
  type        = bool
  description = "Whether to create a dedicated encrypted private S3 audit bucket for CloudTrail"
  default     = true
}

variable "audit_bucket_name" {
  type        = string
  description = "Custom S3 audit bucket name (if empty, auto-generated)"
  default     = ""
}

variable "audit_bucket_force_destroy" {
  type        = bool
  description = "Whether to allow force destroy on the audit bucket"
  default     = false
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Logs retention period in days"
  default     = 90
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
