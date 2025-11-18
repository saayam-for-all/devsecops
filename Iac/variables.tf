variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "user_name" {
  description = "IAM user name"
  type        = string
}

variable "user_managed_policies" {
  description = "AWS managed policies to attach to IAM user"
  type        = list(string)
  default     = []
}

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "role_managed_policies" {
  description = "AWS managed policies to attach to IAM role"
  type        = list(string)
  default     = []
}
