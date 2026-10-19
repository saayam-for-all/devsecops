# AWS Systems Manager Parameter Store Integration Guide

## 1. Purpose

AWS Systems Manager Parameter Store provides centralized configuration management for Saayam for All microservices. It allows services to retrieve configuration and secrets at runtime instead of storing sensitive values in local `.env` files or source code.

This guide describes a recommended integration pattern. AWS resources, IAM policies, and application integrations must be configured and verified by the infrastructure maintainers before production use.

## 2. Parameter Naming Convention

Use a consistent hierarchy that identifies the application, environment, service, and configuration key.

Recommended format:

`/saayam/<environment>/<service>/<parameter-name>`

Examples:

- `/saayam/dev/help-request/redis-endpoint`
- `/saayam/dev/help-request/database-url`
- `/saayam/prod/organization/database-password`

Use lowercase names and keep development, staging, and production parameters separate. Do not include actual passwords, tokens, or other secret values in parameter names.

## 3. Parameter Types

Choose the parameter type according to the data being stored.

| Type | Recommended use |
|---|---|
| `String` | Non-sensitive configuration, such as feature flags |
| `StringList` | Comma-separated, non-sensitive values |
| `SecureString` | Passwords, tokens, and other sensitive configuration |

Use `SecureString` for sensitive values and AWS KMS encryption according to the organization's security requirements. Restrict access to decryption operations.

Parameter Store is not a substitute for proper secret rotation, application authentication, or access control.

## 4. IAM Access Principles

Each microservice should have its own IAM role or appropriately scoped workload identity.

Follow least-privilege access:

- Grant `ssm:GetParameter` or `ssm:GetParameters` only for the parameter paths a service requires.
- Grant `kms:Decrypt` only when required for customer-managed KMS keys, scoped to the appropriate key.
- Avoid broad permissions such as `ssm:*` or access to every parameter in the account.
- Do not use long-lived AWS access keys embedded in application code.
- Prefer the workload's IAM role or another approved temporary-credential mechanism.

The exact IAM resource ARNs and policies must be verified against the deployed account, region, and encryption configuration.

## 5. Retrieving Parameters

Applications should retrieve parameters using the AWS SDK for their language and the approved AWS identity mechanism.

Example using the AWS CLI for a non-sensitive parameter:

```bash
aws ssm get-parameter \
  --name "/saayam/dev/help-request/redis-endpoint" \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text
```

For a secret, request decryption only when the application needs the plaintext value:

```bash
aws ssm get-parameter \
  --name "/saayam/dev/help-request/database-password" \
  --with-decryption \
  --region us-east-1 \
  --query "Parameter.Value" \
  --output text
```

These commands require valid AWS credentials and the appropriate IAM permissions. Use approved local development credentials; never commit credentials or command output containing secrets.

Applications should handle missing parameters, access-denied errors, throttling, and transient service failures without logging sensitive values.

## 6. Regional Configuration

Saayam's infrastructure requirements identify Virginia (`us-east-1`) and Ireland (`eu-west-1`).

Parameter Store is regional. Create and manage parameters in the region used by the application, or use an explicitly approved replication or synchronization strategy.

Do not assume that a parameter created in one region is automatically available in another. Keep regional configuration consistent while ensuring that secrets are handled according to the organization's security and data-handling requirements.

## 7. Operational and Security Recommendations

- Retrieve configuration at startup or through a controlled refresh mechanism.
- Cache configuration in memory only when appropriate for the application's security and rotation requirements.
- Never print secret values in application logs, CI output, or error messages.
- Use AWS CloudTrail and the organization's monitoring controls to audit relevant access.
- Define an approved process for updating, rotating, and removing parameters.
- Keep local development configuration separate from production secrets.
- Document required parameter names and types, not their secret values.

## 8. Validation Checklist

Before enabling a microservice to use Parameter Store, verify:

- [ ] Required parameter names and types are documented.
- [ ] Parameters exist in the intended AWS account and region.
- [ ] The service identity can read only the parameters it needs.
- [ ] KMS permissions are appropriately scoped for encrypted parameters.
- [ ] Applications handle missing parameters and AWS API failures.
- [ ] Secrets do not appear in logs, source control, or CI output.
- [ ] Access, rotation, and regional configuration have been reviewed by the infrastructure maintainers.

## 9. Scope and Limitations

This guide documents an integration pattern; it does not provision AWS resources, create IAM roles, or modify microservice code. Those activities require implementation and review in the relevant infrastructure and application repositories.

Live access and integration testing must be performed by authorized maintainers in an approved AWS environment.