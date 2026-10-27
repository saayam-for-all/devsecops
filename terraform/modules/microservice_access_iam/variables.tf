# --------------------------------------------------------------------------------------------------
# Module Variables: Microservice Least-Privilege IAM Access (ElastiCache & SSM)
# Description: Defines input variables for generating zero-privilege IAM policies and roles
#              scoped strictly to team/service namespaces in SSM and specific ElastiCache clusters.
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

variable "team_name" {
  type        = string
  description = "Team identifier (e.g., volunteer, request, notification, devsecops)"
}

variable "service_name" {
  type        = string
  description = "Microservice name (e.g., profile-service, matching-service)"
}

variable "regions" {
  type        = list(string)
  description = "AWS regions for resource ARNs (Virginia us-east-1 and Ireland eu-west-1)"
  default     = ["us-east-1", "eu-west-1"]
}

variable "elasticache_replication_group_ids" {
  type        = list(string)
  description = "IDs of the ElastiCache replication groups to permit connection to"
  default     = []
}

variable "ssm_path_patterns" {
  type        = list(string)
  description = "Custom SSM parameter paths to grant access to. If empty, automatically defaults to '/{team_name}/*'"
  default     = []
}

variable "allow_shared_team_parameters" {
  type        = bool
  description = "Whether to allow access to shared organizational parameters under '/shared/*'"
  default     = true
}

variable "kms_key_arns" {
  type        = list(string)
  description = "KMS key ARNs allowed for decrypting SecureString parameters"
  default     = []
}

variable "create_role" {
  type        = bool
  description = "Whether to create a dedicated IAM role for the microservice"
  default     = true
}

variable "trusted_service_principals" {
  type        = list(string)
  description = "AWS service principals trusted to assume the role (e.g., ecs-tasks.amazonaws.com, lambda.amazonaws.com)"
  default     = ["ecs-tasks.amazonaws.com", "lambda.amazonaws.com"]
}

variable "trusted_role_arns" {
  type        = list(string)
  description = "IAM user or role ARNs allowed to assume this microservice role (e.g. developers or CI/CD runners)"
  default     = []
}

variable "eks_oidc_issuer_url" {
  type        = string
  description = "EKS cluster OIDC issuer URL (without https://) for EKS IAM Roles for Service Accounts (IRSA)"
  default     = ""
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "EKS cluster OIDC provider ARN for IRSA trust relationship"
  default     = ""
}

variable "eks_service_account_namespace" {
  type        = string
  description = "Kubernetes namespace for EKS IRSA"
  default     = "default"
}

variable "eks_service_account_name" {
  type        = string
  description = "Kubernetes service account name for EKS IRSA"
  default     = ""
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration in seconds (1 to 12 hours)"
  default     = 3600
}

variable "tags" {
  type        = map(string)
  description = "Tags to attach to IAM resources"
  default     = {}
}
