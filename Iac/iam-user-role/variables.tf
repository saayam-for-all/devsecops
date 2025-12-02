variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "user_name" {
  type = string
}

variable "role_name" {
  type = string
}

variable "user_managed_policies" {
  type        = list(string)
  default     = []
}

variable "role_managed_policies" {
  type        = list(string)
  default     = []
}
