terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# create function src code -> function-lambda
# create s3 bucket -> bucket.tf
# package it as zip and upload to S3 -> bucket.tf
# create lambda and point to S3 zip -> lambda.tf
# create api-gateway -> api-gateway.tf
# associate api-gateway with lambda -> lambda-gateway.tf