# Hardened Regional Private S3 Bucket Module

## Overview
This module provisions S3 buckets adhering to the Saayam DevSecOps zero-privilege security architecture:
- **Zero Public Access**: Strict enforcement of `aws_s3_bucket_public_access_block` (blocking all public ACLs, policies, and bucket access).
- **Disabled ACLs**: `BucketOwnerEnforced` setting ensuring all objects are owned by the bucket owner.
- **Data Protection & Encryption**: Default SSE-S3 AES256 or KMS with S3 Bucket Key enabled to minimize cryptographic overhead.
- **Zero-Privilege Bucket Policy**:
  - Enforces TLS encryption for all transit (`aws:SecureTransport = false` Deny rule).
  - Enforces modern TLS 1.2+ protocol minimums.
  - Denies unencrypted uploads lacking proper SSE headers.
  - Grants access only to explicitly enumerated IAM principals.

## Usage Example

```hcl
module "qa_private_virginia" {
  source = "../../modules/s3_private_bucket"

  bucket_name   = "qa-private-virginia"
  environment   = "qa"
  sse_algorithm = "AES256"

  enable_versioning      = true
  enable_lifecycle_rules = true

  tags = {
    Team   = "DevSecOps"
    Region = "us-east-1"
  }
}
```
