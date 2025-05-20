output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.storage.id
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.storage.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.storage.arn
}