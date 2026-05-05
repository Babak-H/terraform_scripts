terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. create function source code -> function-lambda
# 2. create s3 bucket -> bucket.tf
# 3. upload function-lambda.zip to S3 -> bucket.tf
# 4. create lambda and point to S3 zip -> lambda.tf
# 5. create api-gateway -> api-gateway.tf
# 6. associate api-gateway with lambda -> lambda-gateway.tf
