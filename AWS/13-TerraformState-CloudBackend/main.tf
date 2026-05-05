terraform {
  ## AFTER RUNNING TERRAFORM APPLY (WITH LOCAL BACKEND) YOU WILL UNCOMMENT THIS CODE THEN RERUN TERRAFORM INIT
  ## TO SWITCH FROM LOCAL BACKEND TO REMOTE AWS BACKEND
  
  # backend "s3" {
  #   bucket       = "my-cloud-tf-state"
  #   key          = "/dev/stat-file/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# here we create an S3 bucket to host our terraform state file
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "my-cloud-tf-state" 
  force_destroy = true
}

# apply versioning to the bucket
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# apply at rest encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket 
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
