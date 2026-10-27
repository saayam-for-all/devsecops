# --------------------------------------------------------------------------------------------------
# Terraform Module: Hardened Regional Private S3 Bucket
# Description: Provisions an S3 bucket with full privacy hardening:
#              - Block all public access (aws_s3_bucket_public_access_block)
#              - Bucket Owner Enforced (disables ACLs)
#              - Default Server-Side Encryption (AES256 / KMS) with Bucket Key enabled
#              - Object Versioning & Lifecycle Rules
#              - Zero-privilege bucket policy (TLS 1.2+ only, deny unencrypted requests)
# --------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Region      = data.aws_region.current.name
      ManagedBy   = "Terraform"
      Repository  = "devsecops"
      Privacy     = "Private-ZeroPrivilege"
      BucketName  = var.bucket_name
    }
  )
}

# --------------------------------------------------------------------------------------------------
# 1. S3 Bucket Resource
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.common_tags
}

# --------------------------------------------------------------------------------------------------
# 2. Strict Public Access Block (Privacy Hardening Guardrail)
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------------------------------------------------------
# 3. Ownership Controls: Disable ACLs (BucketOwnerEnforced)
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# --------------------------------------------------------------------------------------------------
# 4. Default Server-Side Encryption (SSE-S3 AES256 or KMS)
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" && var.kms_key_arn != "" ? var.kms_key_arn : null
    }
    bucket_key_enabled = true
  }
}

# --------------------------------------------------------------------------------------------------
# 5. Versioning Configuration
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# --------------------------------------------------------------------------------------------------
# 6. Lifecycle Management: Abort Multipart Uploads & Clean Noncurrent Versions
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.enable_versioning && var.noncurrent_version_expiration_days > 0 ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }
  }
}

# --------------------------------------------------------------------------------------------------
# 7. Zero-Privilege IAM Bucket Policy
#    - Denies all HTTP / insecure transport requests
#    - Denies TLS versions < 1.2
#    - Denies unencrypted uploads
#    - Restricts Allow access solely to authorized principals (if specified)
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "EnforceTLSRequestsOnly"
          Effect = "Deny"
          Principal = "*"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket",
            "s3:DeleteObject"
          ]
          Resource = [
            aws_s3_bucket.this.arn,
            "${aws_s3_bucket.this.arn}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        },
        {
          Sid    = "EnforceTLSVersion"
          Effect = "Deny"
          Principal = "*"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.this.arn,
            "${aws_s3_bucket.this.arn}/*"
          ]
          Condition = {
            NumericLessThan = {
              "s3:TlsVersion" = "1.2"
            }
          }
        },
        {
          Sid    = "DenyIncorrectEncryptionHeader"
          Effect = "Deny"
          Principal = "*"
          Action = [
            "s3:PutObject"
          ]
          Resource = "${aws_s3_bucket.this.arn}/*"
          Condition = {
            StringNotEquals = {
              "s3:x-amz-server-side-encryption" = var.sse_algorithm
            }
          }
        }
      ],
      length(var.allowed_principal_arns) > 0 ? [
        {
          Sid    = "AllowExplicitAuthorizedPrincipals"
          Effect = "Allow"
          Principal = {
            AWS = var.allowed_principal_arns
          }
          Action = var.allowed_actions
          Resource = [
            aws_s3_bucket.this.arn,
            "${aws_s3_bucket.this.arn}/*"
          ]
        }
      ] : []
    )
  })

  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}
