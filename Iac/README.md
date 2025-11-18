# Terraform – IAM User + Assume Role Setup

This module creates:

- An IAM user with programmatic access
- IAM user policies (optional)
- An IAM role that the user can assume
- IAM role policies
- Access keys as sensitive outputs

## Inputs

| Variable | Description | Required |
|---------|-------------|----------|
| user_name | IAM user name | Yes |
| role_name | IAM role name | Yes |
| user_managed_policies | List of user policies | No |
| role_managed_policies | List of role policies | No |
| region | AWS region | No |

## Outputs

- iam_user_arn
- iam_user_access_key_id
- iam_user_secret_access_key
- project_role_arn

## Example Usage

```hcl
module "iam_setup" {
  source = "./terraform-iam-user-role"

  user_name            = "dev-user"
  role_name            = "VolunteerMicroServices-S3-ProfilePicUpload"

  user_managed_policies = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  role_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}