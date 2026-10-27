# QA Environment Infrastructure (Issue #65)

## Overview
This environment provisions the dedicated QA infrastructure for Saayam:
1. **QA Cognito User Pool (`QAUserPool`)**:
   - Exact replica of `DevUserPool` schema, password policies, MFA configurations, and custom attributes (`custom:role`, `custom:organization_id`, `custom:volunteer_id`, `custom:kyc_verified`).
   - Cognito Advanced Security Features enabled (`ENFORCED`).
   - Logging configured: AWS CloudTrail event trail routing all Cognito events + CloudWatch Log Group and dedicated log streams for attached Lambda triggers.
   - Public App Client configured for `QA_saayam-netlify.app` with zero client secret and secure token lifetimes.
2. **Hardened Regional S3 Buckets**:
   - `qa-private-virginia` (us-east-1) / `qa-private-ireland` (eu-west-1).
   - Strict public access block, bucket owner enforced, SSE-S3 AES256, and zero-privilege TLS 1.2+ bucket policies.
3. **Netlify Webapp SSM Parameters**:
   - Exports all required frontend configuration under `/saayam/qa/cognito/*` into AWS Systems Manager Parameter Store.
