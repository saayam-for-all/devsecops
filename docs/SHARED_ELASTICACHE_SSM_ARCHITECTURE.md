# Shared AWS ElastiCache & Parameter Store Architecture Guide

**Issue Reference:** [#74: Provision Shared AWS ElastiCache and Parameter Store Instances](https://github.com/saayam-for-all/devsecops/issues/74)  
**Author:** DevSecOps Team  
**Scope:** Shared caching infrastructure and centralized configuration management across Saayam microservices (Volunteer, Request, Notification, etc.) with zero-privilege security and lowest-cost architecture.

---

## 1. Cost Evaluation: Valkey vs. Redis & Parameter Store

### ElastiCache Engine Comparison
AWS ElastiCache supports both **Valkey** (open-source Redis fork governed by the Linux Foundation) and **Redis OSS**.

| Metric / Feature | ElastiCache for Valkey (`cache.t4g.micro`) | ElastiCache for Redis (`cache.t4g.micro`) | Advantage |
| :--- | :--- | :--- | :--- |
| **Hourly Cost (us-east-1)** | **$0.011 / hour** | $0.016 / hour | **~33% cheaper** |
| **Hourly Cost (eu-west-1)** | **$0.011 / hour** | $0.016 / hour | **~33% cheaper** |
| **Estimated Monthly Cost (1 node)** | **~$8.03 / month** | ~$11.68 / month | **Saves 33% monthly infrastructure cost** |
| **Licensing** | Open-source (BSD 3-Clause) | Dual-licensed (RSALv2 / SSPLv1) | Unencumbered open source |
| **Client & Protocol Compatibility** | 100% compatible with Redis 7.2 APIs | Redis 7.2 | Drop-in replacement for `redis-py`, `ioredis`, etc. |
| **Decision** | **Selected (Default)** | Alternative option supported | Lowest cost choice meeting all requirements |

### AWS Systems Manager Parameter Store Cost
- **Standard Tier Parameters:** **$0.00 / month** (Free tier covers up to 10,000 standard parameters per account per region).
- **KMS Encryption:** SecureString parameters default to the AWS-managed key `alias/aws/ssm`, which eliminates the $1.00/month per Customer Managed Key (CMK) fee.
- **Total SSM Infrastructure Cost:** **$0.00 / month**.

---

## 2. High-Level Architecture & Multi-Region Topology

```mermaid
flowchart TD
    subgraph MultiRegion["Multi-Region Deployment (Virginia us-east-1 & Ireland eu-west-1)"]
        subgraph Microservices["Microservices (EKS / ECS / Lambda)"]
            V["Volunteer Microservice<br/>(profile-service)"]
            R["Request Microservice<br/>(matching-service)"]
            N["Notification Microservice<br/>(dispatcher)"]
        end

        subgraph IAM["Zero-Privilege IAM Roles & Policies"]
            V_IAM["Volunteer IAM Role<br/>Allowed: /volunteer/*, /shared/*<br/>Allowed: ElastiCache Connect"]
            R_IAM["Request IAM Role<br/>Allowed: /request/*, /shared/*<br/>Allowed: ElastiCache Connect"]
        end

        subgraph VPC["Isolated VPC Private Subnets"]
            EC["Shared AWS ElastiCache<br/>(Valkey on cache.t4g.micro)<br/>Port 6379 | In-Transit TLS | At-Rest KMS"]
            SG["ElastiCache Security Group<br/>Ingress: Microservice SGs only<br/>Egress: Blocked"]
        end

        subgraph SSM["AWS Systems Manager Parameter Store"]
            P1["/volunteer/profile-service/db_host"]
            P2["/volunteer/profile-service/db_password (SecureString)"]
            P3["/request/matching-service/api_key (SecureString)"]
            P4["/shared/infrastructure/cache_endpoint"]
        end
    end

    V -->|Assumes| V_IAM
    R -->|Assumes| R_IAM
    V_IAM -->|ssm:GetParameter| P1
    V_IAM -->|ssm:GetParameter| P2
    V_IAM -->|ssm:GetParameter| P4
    R_IAM -->|ssm:GetParameter| P3
    R_IAM -->|ssm:GetParameter| P4
    V -->|TCP + TLS (6379)| EC
    R -->|TCP + TLS (6379)| EC
    EC --- SG
```

---

## 3. Team-Level Parameter Store Hierarchy Standard

Configuration parameters and secrets are organized in a strict team and service hierarchy:
```
/{team-name}/{service-name}/{parameter-key}
```

### Namespace Examples
| Parameter Path | Type | Managed By Team | Description |
| :--- | :--- | :--- | :--- |
| `/volunteer/profile-service/db_host` | `String` | Volunteer | Aurora database hostname |
| `/volunteer/profile-service/db_password` | `SecureString` | Volunteer | Database password (encrypted with KMS) |
| `/request/matching-service/api_key` | `SecureString` | Request | Matching engine service secret key |
| `/notification/dispatcher/sns_topic_arn`| `String` | Notification | Transactional alert topic ARN |
| `/shared/infrastructure/cache_endpoint` | `String` | DevSecOps | Primary Valkey cache endpoint address |
| `/shared/infrastructure/cache_port` | `String` | DevSecOps | Valkey port (6379) |

---

## 4. Zero-Privilege IAM Access Policies

Each microservice receives an IAM role attached to a scoped policy that enforces strict least privilege across both Virginia (`us-east-1`) and Ireland (`eu-west-1`):

### Scoped Permissions Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowTeamScopedSSMRead",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:us-east-1:123456789012:parameter/volunteer/*",
        "arn:aws:ssm:us-east-1:123456789012:parameter/shared/*",
        "arn:aws:ssm:eu-west-1:123456789012:parameter/volunteer/*",
        "arn:aws:ssm:eu-west-1:123456789012:parameter/shared/*"
      ]
    },
    {
      "Sid": "AllowKMSDecryptForSSMSecrets",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "arn:aws:kms:us-east-1:123456789012:alias/aws/ssm",
        "arn:aws:kms:eu-west-1:123456789012:alias/aws/ssm"
      ]
    },
    {
      "Sid": "AllowElastiCacheConnect",
      "Effect": "Allow",
      "Action": [
        "elasticache:Connect"
      ],
      "Resource": [
        "arn:aws:elasticache:us-east-1:123456789012:replicationgroup:saayam-dev-cache",
        "arn:aws:elasticache:eu-west-1:123456789012:replicationgroup:saayam-dev-cache",
        "arn:aws:elasticache:us-east-1:123456789012:user:*",
        "arn:aws:elasticache:eu-west-1:123456789012:user:*"
      ]
    }
  ]
}
```

> [!NOTE]
> Under this architecture, the **Volunteer microservice cannot view or access Request or Notification secrets**, providing complete team isolation.

---

## 5. ElastiCache Connection Details & Code Examples

### Network & Security Rules
- **Port:** `6379`
- **TLS (In-Transit Encryption):** **Required (`ssl=True`)**
- **Security Group:** Inbound traffic only permitted from designated microservice security groups or private VPC CIDR.

### Python Connection Example (`redis-py`)
Because Valkey is 100% Redis 7.2 compatible, standard Redis libraries work out of the box:

```python
import boto3
import redis

# 1. Fetch parameters from SSM Parameter Store
ssm = boto3.client("ssm", region_name="us-east-1")

cache_endpoint = ssm.get_parameter(Name="/shared/infrastructure/cache_endpoint")["Parameter"]["Value"]
cache_port = int(ssm.get_parameter(Name="/shared/infrastructure/cache_port")["Parameter"]["Value"])
db_password = ssm.get_parameter(Name="/volunteer/profile-service/db_password", WithDecryption=True)["Parameter"]["Value"]

# 2. Connect to ElastiCache (Valkey) with TLS enabled
r = redis.Redis(
    host=cache_endpoint,
    port=cache_port,
    ssl=True,                      # TLS encryption in transit
    ssl_cert_reqs="required",
    decode_responses=True
)

# 3. Cache lookup pattern (Read-through cache)
cache_key = "volunteer:profile:1001"
profile_data = r.get(cache_key)

if profile_data is None:
    # Query database using retrieved db_password
    profile_data = "{'id': 1001, 'name': 'John Doe', 'role': 'volunteer'}"
    # Cache for 1 hour (3600 seconds)
    r.setex(cache_key, 3600, profile_data)
    print("Cache miss - loaded from database and saved to Valkey.")
else:
    print("Cache hit - retrieved directly from Valkey.")
```

### Node.js Connection Example (`ioredis`)
```typescript
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import Redis from "ioredis";

const ssm = new SSMClient({ region: "us-east-1" });

async function getCacheClient() {
  const endpointParam = await ssm.send(new GetParameterCommand({
    Name: "/shared/infrastructure/cache_endpoint"
  }));

  const cache = new Redis({
    host: endpointParam.Parameter?.Value,
    port: 6379,
    tls: {}, // Enables TLS in-transit encryption
    connectTimeout: 5000,
  });

  return cache;
}
```

---

## 6. How to Initialize and Apply the Modules

### Directory Overview
```
terraform/
├── modules/
│   ├── elasticache_shared/       # Valkey / Redis lowest-cost cache module
│   ├── ssm_parameter_store/      # Hierarchical team parameter store module
│   └── microservice_access_iam/  # Least-privilege IAM roles and policies
└── environments/
    ├── dev/                      # Parameterized dev environment (us-east-1 / eu-west-1)
    │   ├── us-east-1.tfvars.example
    │   └── eu-west-1.tfvars.example
    └── multi-region/             # Unified dual-region deployment
```

### Option A: Deploy to Development (Single Region: Virginia or Ireland)

1. Navigate to the development environment:
   ```bash
   cd terraform/environments/dev
   ```

2. Initialize Terraform modules and providers:
   ```bash
   terraform init
   ```

3. Deploy to **Virginia (`us-east-1`)**:
   ```bash
   terraform plan -var-file=us-east-1.tfvars.example -out=tfplan-va
   terraform apply tfplan-va
   ```

4. Deploy to **Ireland (`eu-west-1`)**:
   ```bash
   terraform plan -var-file=eu-west-1.tfvars.example -out=tfplan-irl
   terraform apply tfplan-irl
   ```

---

### Option B: Deploy Simultaneously to Both Regions (`multi-region`)

1. Navigate to the multi-region environment:
   ```bash
   cd terraform/environments/multi-region
   ```

2. Initialize:
   ```bash
   terraform init
   ```

3. Plan and apply:
   ```bash
   terraform plan -out=tfplan-multi
   terraform apply tfplan-multi
   ```

---

## 7. Verification Steps

After applying, verify that the shared resources and policies are active using the AWS CLI:

```bash
# 1. Verify ElastiCache Valkey cluster in Virginia
aws elasticache describe-replication-groups \
  --replication-group-id saayam-dev-cache \
  --region us-east-1

# 2. Verify team-level SSM parameters
aws ssm get-parameters-by-path \
  --path "/volunteer" \
  --recursive \
  --region us-east-1

# 3. Test least-privilege role assumption
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/saayam-dev-volunteer-profile-service-role \
  --role-session-name test-session
```
