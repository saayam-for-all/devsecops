output "user_arn" {
  value = aws_iam_user.dev_user.arn
}

output "access_key_id" {
  value     = aws_iam_access_key.dev_user_key.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.dev_user_key.secret
  sensitive = true
}

output "role_arn" {
  value = aws_iam_role.project_role.arn
}