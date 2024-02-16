terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.31" 
    }
  }
  # adding Backend S3 for remote state Storage
  backend "s3" {
    bucket = "terraform-on-aws-eks"
    key = "dev/eks-cluster/terraform.tfstate"
    region = "us-east-1"

    # for state locking
    dynamodb_table = "dev-ekscluster"
  }
}

provider "aws" {
  region = var.aws_region
  profile = "default"
}