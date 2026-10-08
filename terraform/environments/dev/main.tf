# --------------------------------------------------------------------------------------------------
# Development Environment: IAM User & Role Provisioning
# Root configuration deploying standardized IAM access for Saayam microservice developers.
# --------------------------------------------------------------------------------------------------

# Example 1: Volunteer Microservices S3 Profile Picture Upload Role
module "volunteer_dev_user" {
  source = "../../modules/iam_dev_user_role"

  environment        = var.environment
  project_name       = "volunteer"
  developer_username = var.volunteer_developer_username
  developer_email    = var.volunteer_developer_email
  custom_role_name   = "VolunteerMicroServices-S3-ProfilePicUpload-${var.environment}"

  # S3 bucket permissions scoped specifically to Volunteer Profile Pictures
  s3_bucket_arns            = var.volunteer_s3_bucket_arns
  s3_object_prefix_pattern  = "profile-pics/*"
  s3_allowed_actions = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:AbortMultipartUpload",
    "s3:ListMultipartUploadParts"
  ]

  store_in_secrets_manager     = true
  max_session_duration_seconds = 43200 # 12 hours max session

  tags = {
    Team    = "Volunteer-Backend"
    Service = "volunteer-service"
  }
}

# Example 2: Generic / Dynamic Developers Provisioning via for_each
module "additional_dev_users" {
  for_each = var.additional_developers
  source   = "../../modules/iam_dev_user_role"

  environment        = var.environment
  project_name       = each.value.project_name
  developer_username = each.key
  developer_email    = lookup(each.value, "email", "")
  role_purpose       = lookup(each.value, "role_purpose", "dev-access")
  s3_bucket_arns     = lookup(each.value, "s3_bucket_arns", [])

  store_in_secrets_manager = true

  tags = {
    Team = lookup(each.value, "team", "DevSecOps")
  }
}
