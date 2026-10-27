# --------------------------------------------------------------------------------------------------
# Multi-Region Outputs: Virginia (us-east-1) & Ireland (eu-west-1)
# --------------------------------------------------------------------------------------------------

# ElastiCache Outputs
output "virginia_elasticache_endpoint" {
  description = "Virginia primary Valkey endpoint"
  value       = module.elasticache_virginia.primary_endpoint_address
}

output "virginia_elasticache_port" {
  description = "Virginia Valkey port"
  value       = module.elasticache_virginia.port
}

output "ireland_elasticache_endpoint" {
  description = "Ireland primary Valkey endpoint"
  value       = module.elasticache_ireland.primary_endpoint_address
}

output "ireland_elasticache_port" {
  description = "Ireland Valkey port"
  value       = module.elasticache_ireland.port
}

# SSM Parameter Store Outputs
output "virginia_ssm_parameter_names" {
  description = "SSM parameter names in Virginia"
  value       = module.ssm_virginia.parameter_names
}

output "ireland_ssm_parameter_names" {
  description = "SSM parameter names in Ireland"
  value       = module.ssm_ireland.parameter_names
}

# Microservice IAM Outputs
output "volunteer_microservice_role_arn" {
  description = "Microservice IAM Role ARN for Volunteer Service (covers Virginia + Ireland)"
  value       = module.volunteer_microservice_iam.role_arn
}

output "request_microservice_role_arn" {
  description = "Microservice IAM Role ARN for Request Service (covers Virginia + Ireland)"
  value       = module.request_microservice_iam.role_arn
}

# --------------------------------------------------------------------------------------------------
# Regional Private S3 Bucket ARNs (Issue #65)
# --------------------------------------------------------------------------------------------------
output "virginia_private_buckets" {
  description = "ARNs of hardened regional private S3 buckets in Virginia (us-east-1)"
  value = var.enable_regional_private_s3_buckets ? {
    dev   = module.dev_private_virginia[0].bucket_arn
    qa    = module.qa_private_virginia[0].bucket_arn
    stage = module.stage_private_virginia[0].bucket_arn
    prod  = module.prod_private_virginia[0].bucket_arn
  } : {}
}

output "ireland_private_buckets" {
  description = "ARNs of hardened regional private S3 buckets in Ireland (eu-west-1)"
  value = var.enable_regional_private_s3_buckets ? {
    dev   = module.dev_private_ireland[0].bucket_arn
    qa    = module.qa_private_ireland[0].bucket_arn
    stage = module.stage_private_ireland[0].bucket_arn
    prod  = module.prod_private_ireland[0].bucket_arn
  } : {}
}

# --------------------------------------------------------------------------------------------------
# Cognito User Pool Outputs (Issue #65)
# --------------------------------------------------------------------------------------------------
output "dev_user_pool_id" {
  description = "Cognito User Pool ID for DevUserPool"
  value       = try(module.dev_cognito_user_pool[0].user_pool_id, "")
}

output "qa_user_pool_id" {
  description = "Cognito User Pool ID for QAUserPool"
  value       = try(module.qa_cognito_user_pool[0].user_pool_id, "")
}

output "qa_user_pool_arn" {
  description = "Cognito User Pool ARN for QAUserPool"
  value       = try(module.qa_cognito_user_pool[0].user_pool_arn, "")
}

output "qa_app_client_id" {
  description = "Cognito App Client ID for QA_saayam-netlify.app"
  value       = try(module.qa_cognito_user_pool[0].primary_client_id, "")
}

output "qa_advanced_security_mode" {
  description = "Cognito Advanced Security Mode for QAUserPool"
  value       = try(module.qa_cognito_user_pool[0].advanced_security_mode, "")
}

output "qa_cloudtrail_arn" {
  description = "CloudTrail trail ARN auditing QA Cognito events"
  value       = try(module.qa_cognito_user_pool[0].cloudtrail_arn, "")
}

output "qa_cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for QA Cognito CloudTrail events"
  value       = try(module.qa_cognito_user_pool[0].cloudtrail_log_group_arn, "")
}
