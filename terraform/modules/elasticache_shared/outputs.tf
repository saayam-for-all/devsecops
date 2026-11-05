# --------------------------------------------------------------------------------------------------
# Module Outputs: Shared AWS ElastiCache Cluster
# --------------------------------------------------------------------------------------------------

output "replication_group_id" {
  description = "Identifier of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint address for connection and write operations"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for read-only replica queries (if multi-node)"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Port on which the cache cluster accepts traffic"
  value       = aws_elasticache_replication_group.this.port
}

output "security_group_id" {
  description = "ID of the security group protecting the ElastiCache cluster"
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Name of the parameter group used by the cache cluster"
  value       = aws_elasticache_parameter_group.this.name
}

output "engine" {
  description = "Cache engine configured (valkey or redis)"
  value       = var.engine
}

output "node_type" {
  description = "Node instance type provisioned (cache.t4g.micro)"
  value       = var.node_type
}
