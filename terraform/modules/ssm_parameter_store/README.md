# AWS Systems Manager (SSM) Parameter Store Module

This module provisions standard, hierarchical configurations and secrets for Saayam microservices using **AWS Systems Manager (SSM) Parameter Store** at **zero infrastructure cost**.

---

## Team-Level Hierarchy Standard

Parameters follow the standardized naming convention:
```
/{team-name}/{service-name}/{parameter-name}
```
Or optionally:
```
/{environment}/{team-name}/{service-name}/{parameter-name}
```

### Examples
- `/volunteer/profile-service/db_host` (String)
- `/volunteer/profile-service/db_password` (SecureString)
- `/volunteer/shared/cache_endpoint` (String)
- `/request/matching-service/api_key` (SecureString)
- `/notification/dispatcher/sns_topic_arn` (String)

---

## Cost Optimization
- **Standard Tier ($0.00 / free)**: AWS Parameter Store Standard parameters are completely free for up to 10,000 parameters per account/region with standard API throughput.
- **KMS Encryption**: By default, SecureString uses `alias/aws/ssm` (AWS managed key), avoiding the $1/month per key charge of Customer Managed KMS keys while providing AES-256 GCM encryption at rest.

---

## Usage Example

```hcl
module "ssm_parameters" {
  source = "../../modules/ssm_parameter_store"

  environment = "dev"

  parameters = {
    "db_host" = {
      team        = "volunteer"
      service     = "profile-service"
      type        = "String"
      value       = "aurora-dev.saayam.internal"
      description = "Database host for volunteer profile service"
    }
    "db_password" = {
      team        = "volunteer"
      service     = "profile-service"
      type        = "SecureString"
      value       = "ChangeMeDevPassword123!"
      description = "Database password for volunteer profile service"
    }
    "cache_endpoint" = {
      team        = "volunteer"
      service     = "shared"
      type        = "String"
      value       = module.shared_cache.primary_endpoint_address
      description = "Shared ElastiCache Valkey endpoint"
    }
  }

  tags = {
    ManagedBy = "Terraform"
  }
}
```
