# S3 Bucket for storage
resource "aws_s3_bucket" "storage" {
  bucket = var.storage_bucket_name != "" ? var.storage_bucket_name : "${var.app_name}-storage-${var.suffix}"
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}