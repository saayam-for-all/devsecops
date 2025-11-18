output "iam_user_arn" {
  description = "IAM User ARN"
  value       = aws_iam_user.dev_user.arn
}

output "iam_user_access_key_id" {
  description = "Access Key ID for programmatic access"
  value       = aws_iam_access_key.dev_user_key.id
  sensitive   = true
}

output "iam_user_secret_access_key" {
  description = "Secret access key for programmatic access"
  value       = aws_iam_access_key.dev_user_key.secret
  sensitive   = true
}

output "project_role_arn" {
  description = "IAM project role ARN"
  value       = aws_iam_role.project_role.arn
}