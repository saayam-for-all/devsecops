# --------------------------------------------------------------------------------------------------
# Output Values: Dev Environment
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
