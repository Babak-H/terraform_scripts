locals {
  # Local value for the CloudFront S3 origin ID
  s3_origin_id = "s3-origin"
}

resource "aws_s3_bucket" "babak2023s3bucketjan" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = "Dev"
  }
}

# enable versioning on the bucket
resource "aws_s3_bucket_versioning" "babak-versioning-s3" {
  bucket = aws_s3_bucket.babak2023s3bucketjan.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.babak2023s3bucketjan.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# normally everything on this bucket will become blocked to public
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.babak2023s3bucketjan.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# adding an object to the bucket via terraform
resource "aws_s3_object" "Object1" {
  bucket       = aws_s3_bucket.babak2023s3bucketjan.id
  key          = "Image1.jpg"
  source       = "${path.root}/web-image/Image1.jpg"
  content_type = "image/jpeg"
}

# this policy allows cloudfront to read all the objects inside the S3 bucket
data "aws_iam_policy_document" "allow_cloudfront" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.babak2023s3bucketjan.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.dev-cloudfront1.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.babak2023s3bucketjan.id
  policy = data.aws_iam_policy_document.allow_cloudfront.json
}
