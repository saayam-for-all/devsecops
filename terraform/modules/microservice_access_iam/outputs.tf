# --------------------------------------------------------------------------------------------------
# Module Outputs: Microservice Least-Privilege IAM Access
# --------------------------------------------------------------------------------------------------

output "policy_arn" {
  description = "ARN of the least-privilege IAM policy granting access to team SSM and ElastiCache"
  value       = aws_iam_policy.microservice_policy.arn
}

output "policy_name" {
  description = "Name of the IAM policy"
  value       = aws_iam_policy.microservice_policy.name
}

output "role_arn" {
  description = "ARN of the microservice IAM role (empty if create_role is false)"
  value       = var.create_role ? aws_iam_role.microservice_role[0].arn : null
}

output "role_name" {
  description = "Name of the microservice IAM role (empty if create_role is false)"
  value       = var.create_role ? aws_iam_role.microservice_role[0].name : null
}

output "allowed_ssm_parameter_arns" {
  description = "List of SSM parameter ARNs permitted by this policy (across Virginia and Ireland)"
  value       = local.ssm_parameter_arns
}

output "allowed_elasticache_arns" {
  description = "List of ElastiCache ARNs permitted by this policy"
  value       = local.elasticache_arns
}
