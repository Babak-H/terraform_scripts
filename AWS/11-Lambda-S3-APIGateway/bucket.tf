# generate a globally unique bucket name
resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda"
  length = 2
}

# create s3 bucket
resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = random_pet.lambda_bucket_name.id
  force_destroy = true
}

# block all public access
resource "aws_s3_bucket_public_access_block" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# save the lambda function src as a zip file
data "archive_file" "hello_lambda" {
  type = "zip"

  source_dir  = "./function-lambda"
  output_path = "./function-lambda.zip"
}

# upload the Lambda deployment package to S3 (add an object to the S3 bucket)
resource "aws_s3_object" "hello_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "function-lambda.zip"
  source = "${path.module}/function-lambda.zip"

  # trigger an update when the local zip file changes
  source_hash = filebase64sha256("${path.module}/function-lambda.zip")
}
