# Microservice Least-Privilege IAM Access Module (ElastiCache & SSM)

This module provisions zero-privilege IAM policies and roles for Saayam microservices (Volunteer, Request, Notification, etc.), granting **strictly scoped access** to:
1. **SSM Parameter Store**: Restricted to the microservice's team hierarchy (e.g. `/{team-name}/*`) and decryption via KMS.
2. **ElastiCache**: Restricted to authorized cache replication groups using IAM authentication.

---

## Zero-Privilege Security Model
- **No Wildcard `Resource: *`**: Policies strictly whitelist specific ARN patterns for the team.
- **Cross-Team Isolation**: Volunteer microservices cannot read secrets or parameters owned by Request or Notification services.
- **Multi-Region Consistency**: Automatically scopes policies across both Virginia (`us-east-1`) and Ireland (`eu-west-1`).
- **Flexible Workloads**: Supports AWS ECS Task roles, AWS Lambda execution roles, EKS IAM Roles for Service Accounts (IRSA), or local developer assume-role workflows.

---

## Usage Example

```hcl
module "volunteer_service_iam" {
  source = "../../modules/microservice_access_iam"

  environment  = "dev"
  team_name    = "volunteer"
  service_name = "profile-service"

  # Grant access to Virginia (us-east-1) and Ireland (eu-west-1)
  regions = ["us-east-1", "eu-west-1"]

  # Scope to shared cache cluster
  elasticache_replication_group_ids = [module.shared_cache.replication_group_id]

  # Allow ECS tasks and Lambda functions to assume this role
  trusted_service_principals = [
    "ecs-tasks.amazonaws.com",
    "lambda.amazonaws.com"
  ]

  tags = {
    Team = "Volunteer-Backend"
  }
}
```
