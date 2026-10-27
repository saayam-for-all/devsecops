# --------------------------------------------------------------------------------------------------
# Output Values: AWS Cognito User Pool Module
# --------------------------------------------------------------------------------------------------

output "user_pool_id" {
  description = "The ID of the provisioned Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "The ARN of the provisioned Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_name" {
  description = "The name of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.name
}

output "user_pool_endpoint" {
  description = "The endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.endpoint
}

output "primary_client_id" {
  description = "The ID of the primary app client (e.g. for QA_saayam-netlify.app)"
  value       = aws_cognito_user_pool_client.primary_app_client.id
}

output "primary_client_name" {
  description = "The name of the primary app client"
  value       = aws_cognito_user_pool_client.primary_app_client.name
}

output "additional_client_ids" {
  description = "Map of client names to IDs for additional app clients"
  value       = { for k, v in aws_cognito_user_pool_client.additional_clients : k => v.id }
}

output "domain" {
  description = "Cognito hosted UI domain prefix if configured"
  value       = try(aws_cognito_user_pool_domain.this[0].domain, "")
}

output "advanced_security_mode" {
  description = "Status of Cognito Advanced Security Features"
  value       = var.advanced_security_mode
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail auditing Cognito events"
  value       = try(aws_cloudtrail.cognito_trail[0].arn, "")
}

output "cloudtrail_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for Cognito CloudTrail events"
  value       = try(aws_cloudwatch_log_group.cognito_cloudtrail[0].arn, "")
}

output "audit_bucket_id" {
  description = "ID / Name of the S3 audit bucket storing CloudTrail event logs"
  value       = try(aws_s3_bucket.audit_bucket[0].id, var.audit_bucket_name)
}

output "lambda_trigger_log_groups" {
  description = "Map of Lambda trigger names to their dedicated CloudWatch Log Group ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.lambda_triggers : k => v.arn }
}
