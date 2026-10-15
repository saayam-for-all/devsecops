terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary Virginia Provider (us-east-1)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Organization = "Saayam"
      Environment  = var.environment
      Region       = "us-east-1"
      ManagedBy    = "Terraform"
      Repository   = "devsecops"
    }
  }
}

# Secondary Ireland Provider (eu-west-1)
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"

  default_tags {
    tags = {
      Organization = "Saayam"
      Environment  = var.environment
      Region       = "eu-west-1"
      ManagedBy    = "Terraform"
      Repository   = "devsecops"
    }
  }
}

# Default provider for global IAM resources
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Organization = "Saayam"
      Environment  = var.environment
      ManagedBy    = "Terraform"
      Repository   = "devsecops"
    }
  }
}
