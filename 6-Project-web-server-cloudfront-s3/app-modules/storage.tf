# local variable to use in this file
locals {
  s3_origin_id = "s3-origin"
}

resource "aws_s3_bucket" "babak2023s3bucketjan" {
  bucket = var.bucket_name
  
  tags = {
    Name = var.bucket_name
    Environment = "Dev"
  }

  provisioner "local-exec" {
    command = "git clone https://github.com/vineets300/Webpage1.git web-server-image"
  }
}

resource "aws_s3_bucket_versioning" "babak-versioning-s3" {
  bucket = aws_s3_bucket.babak2023s3bucketjan.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "babak-acl-s3" {
  bucket = aws_s3_bucket.babak2023s3bucketjan.id
  acl= var.s3-acl
}

resource "aws_s3_account_public_access_block" "public_storage" {
  depends_on = [aws_s3_bucket.babak2023s3bucketjan]
  block_public_acls = false
  block_public_policy = false
}

resource "aws_s3_object" "Object1" {
  depends_on = [aws_s3_bucket.babak2023s3bucketjan]
  bucket = var.bucket_name
  key = "Image1.jpg"
  source = "web-image/Image1.jpg"
  acl = var.s3-acl
}