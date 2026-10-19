# --------------------------------------------------------------------------------------------------
# Module Outputs: AWS Systems Manager (SSM) Parameter Store
# --------------------------------------------------------------------------------------------------

output "parameter_names" {
  description = "List of all provisioned SSM parameter hierarchical names"
  value       = [for p in aws_ssm_parameter.parameters : p.name]
}

output "parameter_arns" {
  description = "List of all provisioned SSM parameter ARNs"
  value       = [for p in aws_ssm_parameter.parameters : p.arn]
}

output "parameters" {
  description = "Map of parameter keys to their name, ARN, and type"
  value = {
    for k, p in aws_ssm_parameter.parameters : k => {
      name = p.name
      arn  = p.arn
      type = p.type
      version = p.version
    }
  }
}

output "team_prefixes" {
  description = "List of team hierarchy prefix patterns (e.g., /volunteer/*)"
  value = distinct([
    for k, v in var.parameters : var.prefix_environment ? (
      "/${var.environment}/${lower(v.team)}/*"
    ) : (
      "/${lower(v.team)}/*"
    )
  ])
}

output "kms_key_arn" {
  description = "KMS key ARN used for SecureString parameters"
  value       = local.active_kms_key_arn
}
