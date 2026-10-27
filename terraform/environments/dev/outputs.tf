# --------------------------------------------------------------------------------------------------
# Output Values: Dev Environment
# --------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
# Shared ElastiCache (Valkey) Outputs
# --------------------------------------------------------------------------------------------------
output "elasticache_primary_endpoint" {
  description = "Primary endpoint address for shared ElastiCache (Valkey) cluster"
  value       = length(module.shared_elasticache) > 0 ? module.shared_elasticache[0].primary_endpoint_address : "Not provisioned"
}

output "elasticache_port" {
  description = "Port number for shared ElastiCache cluster"
  value       = length(module.shared_elasticache) > 0 ? module.shared_elasticache[0].port : 6379
}

output "elasticache_security_group_id" {
  description = "Security group ID for shared ElastiCache cluster"
  value       = length(module.shared_elasticache) > 0 ? module.shared_elasticache[0].security_group_id : null
}

output "elasticache_replication_group_id" {
  description = "Replication group ID of the shared cache cluster"
  value       = length(module.shared_elasticache) > 0 ? module.shared_elasticache[0].replication_group_id : null
}

# --------------------------------------------------------------------------------------------------
# SSM Parameter Store Outputs
# --------------------------------------------------------------------------------------------------
output "ssm_parameter_names" {
  description = "Hierarchical parameter names provisioned in SSM Parameter Store"
  value       = length(module.ssm_parameter_store) > 0 ? module.ssm_parameter_store[0].parameter_names : []
}

output "ssm_team_prefixes" {
  description = "Team hierarchy path prefixes"
  value       = length(module.ssm_parameter_store) > 0 ? module.ssm_parameter_store[0].team_prefixes : []
}

# --------------------------------------------------------------------------------------------------
# Microservice IAM Outputs (Scoped to Virginia & Ireland)
# --------------------------------------------------------------------------------------------------
output "volunteer_microservice_role_arn" {
  description = "IAM Role ARN for Volunteer Profile Service"
  value       = module.volunteer_microservice_iam.role_arn
}

output "volunteer_microservice_policy_arn" {
  description = "Least-privilege Policy ARN for Volunteer Profile Service"
  value       = module.volunteer_microservice_iam.policy_arn
}

output "request_microservice_role_arn" {
  description = "IAM Role ARN for Request Matching Service"
  value       = module.request_microservice_iam.role_arn
}

output "request_microservice_policy_arn" {
  description = "Least-privilege Policy ARN for Request Matching Service"
  value       = module.request_microservice_iam.policy_arn
}

# --------------------------------------------------------------------------------------------------
# Developer IAM Onboarding Outputs (Issue #75)
# --------------------------------------------------------------------------------------------------
output "volunteer_dev_user_arn" {
  description = "IAM user ARN for the Volunteer service developer"
  value       = module.volunteer_dev_user.developer_user_arn
}

output "volunteer_project_role_arn" {
  description = "Assumable project role ARN for Volunteer S3 uploads"
  value       = module.volunteer_dev_user.project_role_arn
}

output "volunteer_secrets_manager_secret" {
  description = "Secrets Manager secret name containing developer credentials"
  value       = module.volunteer_dev_user.secrets_manager_secret_name
}

output "volunteer_aws_cli_config_snippet" {
  description = "CLI configuration helper snippet"
  value       = module.volunteer_dev_user.aws_cli_config_snippet
}

output "additional_dev_users_summary" {
  description = "Summary of additional provisioned dev users and roles"
  value = {
    for username, dev_module in module.additional_dev_users : username => {
      user_arn    = dev_module.developer_user_arn
      role_arn    = dev_module.project_role_arn
      secret_name = dev_module.secrets_manager_secret_name
    }
  }
}

# --------------------------------------------------------------------------------------------------
# Cognito & Storage Outputs (Issue #65)
# --------------------------------------------------------------------------------------------------
output "dev_user_pool_id" {
  description = "Cognito User Pool ID for DevUserPool"
  value       = try(module.dev_cognito_user_pool[0].user_pool_id, "")
}

output "dev_user_pool_arn" {
  description = "Cognito User Pool ARN for DevUserPool"
  value       = try(module.dev_cognito_user_pool[0].user_pool_arn, "")
}

output "dev_app_client_id" {
  description = "Cognito App Client ID for DevUserPool"
  value       = try(module.dev_cognito_user_pool[0].primary_client_id, "")
}

output "dev_private_bucket_arn" {
  description = "ARN of the hardened regional dev private S3 bucket"
  value       = try(module.dev_private_bucket[0].bucket_arn, "")
}

