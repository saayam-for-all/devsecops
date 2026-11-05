# Shared AWS ElastiCache Module (Valkey / Redis)

This module provisions an AWS ElastiCache cluster optimized for **shared microservice caching** with the **lowest possible cost footprint** using AWS Graviton2 (`cache.t4g.micro`) and **Valkey**.

---

## Cost Evaluation: Valkey vs. Redis

| Feature / Metric | Valkey (`cache.t4g.micro`) | Redis (`cache.t4g.micro`) | Advantage |
| :--- | :--- | :--- | :--- |
| **Hourly Rate (us-east-1)** | **$0.011 / hr** | $0.016 / hr | **~33% cheaper** |
| **Hourly Rate (eu-west-1)** | **$0.011 / hr** | $0.016 / hr | **~33% cheaper** |
| **Monthly Estimate (1 node)**| **~$8.03 / month** | ~$11.68 / month | **Saves ~$44/yr per node** |
| **Licensing** | Open-source (BSD 3-Clause, Linux Foundation) | Dual-licensed (RSALv2 / SSPLv1) | Safe, unencumbered open source |
| **API Compatibility** | 100% compatible with Redis 7.2 APIs & clients | Redis 7.2 | Drop-in replacement for `redis-py`, `ioredis`, etc. |
| **Default in this Module** | **Yes (`engine = "valkey"`)** | Available (`engine = "redis"`) | Default lowest-cost choice |

---

## Features
- **Zero-Privilege Security**: Isolated security group allowing ingress strictly on port 6379 from designated microservice security groups or CIDR blocks.
- **In-Transit TLS & At-Rest Encryption**: In-transit TLS is enforced by default; optional at-rest KMS key support.
- **Microsecond In-Memory Performance**: LRU eviction policies configured out-of-the-box (`volatile-lru`).
- **Multi-Region Support**: Region-agnostic; seamlessly deploys to Virginia (`us-east-1`) and Ireland (`eu-west-1`).

---

## Usage Example

```hcl
module "shared_cache" {
  source = "../../modules/elasticache_shared"

  name_prefix = "saayam"
  environment = "dev"
  engine      = "valkey"          # Lowest-cost engine
  node_type   = "cache.t4g.micro" # Lowest-cost instance type

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  allowed_security_group_ids = [
    module.volunteer_service_sg.security_group_id,
    module.request_service_sg.security_group_id
  ]

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  tags = {
    Team = "DevSecOps"
  }
}
```
