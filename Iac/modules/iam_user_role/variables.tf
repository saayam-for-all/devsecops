variable "user_name" {
  type        = string
  description = "IAM user name"
}

variable "role_name" {
  type        = string
  description = "IAM role name"
}

variable "user_managed_policies" {
  type        = list(string)
  description = "List of AWS managed policies to attach to user"
  default     = []
}

variable "role_managed_policies" {
  type        = list(string)
  description = "List of AWS managed policies to attach to role"
  default     = []
}