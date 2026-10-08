# --------------------------------------------------------------------------------------------------
# Output Values: Standardized IAM Developer User & Project Role Setup
# --------------------------------------------------------------------------------------------------

output "developer_user_name" {
  description = "The name of the created developer IAM user"
  value       = aws_iam_user.developer.name
}

output "developer_user_arn" {
  description = "The ARN of the created developer IAM user"
  value       = aws_iam_user.developer.arn
}

output "project_role_name" {
  description = "The name of the created project IAM role"
  value       = aws_iam_role.project_role.name
}

output "project_role_arn" {
  description = "The ARN of the project IAM role to be assumed by the developer"
  value       = aws_iam_role.project_role.arn
}

output "secrets_manager_secret_name" {
  description = "The name of the AWS Secrets Manager secret storing the credentials"
  value       = length(aws_secretsmanager_secret.developer_credentials) > 0 ? aws_secretsmanager_secret.developer_credentials[0].name : null
}

output "secrets_manager_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret storing the credentials"
  value       = length(aws_secretsmanager_secret.developer_credentials) > 0 ? aws_secretsmanager_secret.developer_credentials[0].arn : null
}

output "aws_cli_config_snippet" {
  description = "Sample AWS CLI ~/.aws/config configuration block for the developer to assume this role"
  value       = <<-EOT
    # Add to ~/.aws/config:
    [profile saayam-${var.environment}-${var.project_name}]
    role_arn = ${aws_iam_role.project_role.arn}
    source_profile = saayam-${var.environment}-${var.developer_username}
    region = ${data.aws_region.current.name}
    output = json
  EOT
}
