# AWS Cognito User Pool Terraform Module

## Overview
This module provisions a production-ready AWS Cognito User Pool adhering to Saayam DevSecOps standards:
- **Schema Replication**: Exact replication of standard attributes (`email`, `name`, `phone_number`, `given_name`, `family_name`) and Saayam custom attributes (`custom:role`, `custom:organization_id`, `custom:volunteer_id`, `custom:kyc_verified`).
- **Cognito Advanced Security Features**: Built-in toggle for `ENFORCED` or `AUDIT` mode (adaptive authentication, compromised credential checks, risk evaluation).
- **MFA & Password Policies**: Enforces complex password requirements and software-token MFA (TOTP).
- **App Clients**: Zero-secret public web app client configuration for Single Page Applications (e.g. `QA_saayam-netlify.app`).
- **Comprehensive Logging & Auditing**:
  - AWS CloudTrail trail capturing Cognito User Pool management and data events.
  - Dedicated CloudWatch Log Group with configurable retention for real-time log ingestion.
  - Dedicated CloudWatch Log Groups & Streams for attached Cognito Lambda triggers.
- **Secure S3 Audit Storage**: CloudTrail logs stored in a private, encrypted bucket with complete Public Access Block and zero-privilege TLS enforcement.

## Usage Example

```hcl
module "qa_cognito_user_pool" {
  source = "../../modules/cognito_user_pool"

  environment            = "qa"
  user_pool_name         = "QAUserPool"
  advanced_security_mode = "ENFORCED"
  mfa_configuration      = "OPTIONAL"

  client_name = "saayam-qa-webapp-client"
  client_callback_urls = [
    "https://QA_saayam-netlify.app/callback",
    "https://QA_saayam-netlify.app"
  ]
  client_logout_urls = [
    "https://QA_saayam-netlify.app/logout"
  ]

  enable_cloudtrail_logging = true
  log_retention_days        = 90

  tags = {
    Team    = "DevSecOps"
    Purpose = "QA-Authentication"
  }
}
```
