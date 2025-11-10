terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# Create IAM User
# ---------------------------
resource "aws_iam_user" "example_user" {
  name = "example-user"
}

# simple managed policy (optional)
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.example_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------------------------
# Create IAM Role
# ---------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.example_user.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example_role" {
  name               = "example-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach a policy to the role (optional)
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.example_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ---------------------------
# Outputs
# ---------------------------
output "user_arn" {
  value = aws_iam_user.example_user.arn
}

output "role_arn" {
  value = aws_iam_role.example_role.arn
}
