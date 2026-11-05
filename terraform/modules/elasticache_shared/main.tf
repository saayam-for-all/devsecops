# --------------------------------------------------------------------------------------------------
# Module: Shared AWS ElastiCache Cluster (Valkey / Redis)
# Description: Modular provisioning of lowest-cost shared cache infrastructure for Saayam
#              microservices with strict network isolation, in-transit encryption, and at-rest encryption.
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

locals {
  cluster_name = "${var.name_prefix}-${var.environment}-cache"
  default_pg_family = lower(var.engine) == "valkey" ? "valkey7" : "redis7"
  pg_family         = var.parameter_group_family != "" ? var.parameter_group_family : local.default_pg_family

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Engine      = var.engine
      NodeType    = var.node_type
      ManagedBy   = "Terraform"
      Repository  = "devsecops"
      Service     = "shared-elasticache"
    }
  )
}

# --------------------------------------------------------------------------------------------------
# 1. ElastiCache Subnet Group (Private Isolated Subnets)
# --------------------------------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name_prefix}-${var.environment}-cache-subnet-group"
  description = "Subnet group for shared ${var.engine} cluster in ${var.environment}"
  subnet_ids  = var.subnet_ids

  tags = local.common_tags
}

# --------------------------------------------------------------------------------------------------
# 2. Least-Privilege Security Group for ElastiCache
#    - Ingress strictly restricted to authorized microservice security groups or CIDRs
#    - No outbound public Internet egress
# --------------------------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-${var.environment}-cache-sg"
  description = "Security group for shared ${var.engine} cluster (port ${var.port})"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-${var.environment}-cache-sg"
    }
  )
}

# Ingress: Allow traffic on cache port from authorized microservice security groups
resource "aws_security_group_rule" "ingress_security_groups" {
  count                    = length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this.id
  description              = "Allow inbound traffic on port ${var.port} from microservice SG"
}

# Ingress: Allow traffic on cache port from authorized VPC/Subnet CIDRs
resource "aws_security_group_rule" "ingress_cidrs" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this.id
  description       = "Allow inbound traffic on port ${var.port} from authorized CIDRs"
}

# --------------------------------------------------------------------------------------------------
# 3. Custom Parameter Group (Optimized memory policies & timeout)
# --------------------------------------------------------------------------------------------------
resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.name_prefix}-${var.environment}-${lower(var.engine)}-params"
  family      = local.pg_family
  description = "Custom parameter group for shared ${var.engine} in ${var.environment}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# --------------------------------------------------------------------------------------------------
# 4. ElastiCache Replication Group (Valkey / Redis)
#    - Lowest cost node type: cache.t4g.micro (ARM Graviton2)
#    - In-transit TLS and At-Rest KMS encryption enforced
# --------------------------------------------------------------------------------------------------
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.cluster_name
  description          = "Shared ${var.engine} cache cluster for Saayam microservices (${var.environment})"
  
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port

  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.this.id]

  num_cache_clusters         = var.num_cache_nodes
  automatic_failover_enabled = var.num_cache_nodes > 1 ? var.automatic_failover_enabled : false
  multi_az_enabled           = var.num_cache_nodes > 1 ? var.multi_az_enabled : false

  # Encryption & Zero-Trust Best Practices
  transit_encryption_enabled = var.transit_encryption_enabled
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.kms_key_id != "" ? var.kms_key_id : null
  auth_token                 = var.transit_encryption_enabled && var.auth_token != "" ? var.auth_token : null

  # Maintenance & Cost optimization (0 snapshots in dev avoids extra S3 backup charges)
  maintenance_window       = var.maintenance_window
  snapshot_window          = var.snapshot_retention_limit > 0 ? var.snapshot_window : null
  snapshot_retention_limit = var.snapshot_retention_limit
  apply_immediately        = var.apply_immediately
  auto_minor_version_upgrade = true

  tags = local.common_tags
}
