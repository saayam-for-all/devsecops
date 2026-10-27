# --------------------------------------------------------------------------------------------------
# Output Values: QA Environment
# --------------------------------------------------------------------------------------------------

output "qa_user_pool_id" {
  description = "The Cognito User Pool ID for QA"
  value       = module.qa_cognito_user_pool.user_pool_id
}

output "qa_user_pool_arn" {
  description = "The Cognito User Pool ARN for QA"
  value       = module.qa_cognito_user_pool.user_pool_arn
}

output "qa_app_client_id" {
  description = "The Cognito App Client ID for Netlify QA Webapp"
  value       = module.qa_cognito_user_pool.primary_client_id
}

output "qa_advanced_security_mode" {
  description = "Cognito Advanced Security Mode for QAUserPool"
  value       = module.qa_cognito_user_pool.advanced_security_mode
}

output "qa_cloudtrail_arn" {
  description = "CloudTrail Trail ARN auditing QA Cognito events"
  value       = module.qa_cognito_user_pool.cloudtrail_arn
}

output "qa_cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN receiving Cognito CloudTrail events"
  value       = module.qa_cognito_user_pool.cloudtrail_log_group_arn
}

output "qa_lambda_trigger_log_groups" {
  description = "CloudWatch Log Groups provisioned for Cognito Lambda triggers"
  value       = module.qa_cognito_user_pool.lambda_trigger_log_groups
}

output "qa_private_virginia_bucket_arn" {
  description = "ARN of the qa-private-virginia S3 bucket (if deployed in us-east-1)"
  value       = try(module.qa_private_virginia[0].bucket_arn, "")
}

output "qa_private_ireland_bucket_arn" {
  description = "ARN of the qa-private-ireland S3 bucket (if deployed in eu-west-1)"
  value       = try(module.qa_private_ireland[0].bucket_arn, "")
}

output "ssm_parameter_names" {
  description = "List of exported SSM parameter names for Netlify QA Webapp"
  value       = try(module.ssm_parameter_store[0].parameter_names, [])
}
