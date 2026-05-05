# create the s3 bucket for saving files, version the bucket, encrypt it at rest with default kms key
resource "aws_s3_bucket" "bucket" {
  # give a unique name to the bucket
  bucket        = var.bucket_name
  force_destroy = true
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt objects at rest with Amazon S3 managed keys (SSE)
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
