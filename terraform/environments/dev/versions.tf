terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Example remote S3 backend configuration (Uncomment for team state storage)
  # backend "s3" {
  #   bucket         = "saayam-devsecops-terraform-state"
  #   key            = "dev/iam/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "saayam-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Organization = "Saayam"
      Environment  = "dev"
      ManagedBy    = "Terraform"
      Repository   = "devsecops"
    }
  }
}
