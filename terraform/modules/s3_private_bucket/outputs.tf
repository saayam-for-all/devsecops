# --------------------------------------------------------------------------------------------------
# Output Values: Hardened Regional Private S3 Bucket Module
# --------------------------------------------------------------------------------------------------

output "bucket_id" {
  description = "The name/ID of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region where the bucket resides"
  value       = aws_s3_bucket.this.region
}
