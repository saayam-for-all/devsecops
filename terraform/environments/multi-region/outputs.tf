# --------------------------------------------------------------------------------------------------
# Multi-Region Outputs: Virginia (us-east-1) & Ireland (eu-west-1)
# --------------------------------------------------------------------------------------------------

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

output "virginia_ssm_parameter_names" {
  description = "SSM parameter names in Virginia"
  value       = module.ssm_virginia.parameter_names
}

output "ireland_ssm_parameter_names" {
  description = "SSM parameter names in Ireland"
  value       = module.ssm_ireland.parameter_names
}

output "volunteer_microservice_role_arn" {
  description = "Microservice IAM Role ARN for Volunteer Service (covers Virginia + Ireland)"
  value       = module.volunteer_microservice_iam.role_arn
}

output "request_microservice_role_arn" {
  description = "Microservice IAM Role ARN for Request Service (covers Virginia + Ireland)"
  value       = module.request_microservice_iam.role_arn
}
