# generate a name
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

# upload the zipfile to S3
resource "aws_s3_object" "hello_lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "function-lambda.zip"
  source = data.archive_file.hello_lambda.output_path

  # this triggers an update, when value of the zip file changes
  etag = filemd5(data.archive_file.hello_lambda.output_path)
}
