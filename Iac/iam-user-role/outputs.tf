output "user_arn" {
  value = module.iam_user_role.user_arn
}

output "access_key_id" {
  value     = module.iam_user_role.access_key_id
  sensitive = true
}

output "secret_access_key" {
  value     = module.iam_user_role.secret_access_key
  sensitive = true
}

output "role_arn" {
  value = module.iam_user_role.role_arn
}
