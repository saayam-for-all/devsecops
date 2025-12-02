user_name             = "volunteer-dev-user"
role_name             = "volunteer-dev-role"

user_managed_policies = [
  "arn:aws:iam::aws:policy/ReadOnlyAccess"
]

role_managed_policies = [
  "arn:aws:iam::aws:policy/AmazonS3FullAccess"
]
