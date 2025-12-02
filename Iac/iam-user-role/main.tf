terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "iam-user-role/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "iam_user_role" {
  source                = "../modules/iam_user_role"
  user_name             = var.user_name
  role_name             = var.role_name
  user_managed_policies = var.user_managed_policies
  role_managed_policies = var.role_managed_policies
}
