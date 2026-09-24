# --------------------------------------------------------------------------------------------------
# Input Variables: Dev Environment
# --------------------------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

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
