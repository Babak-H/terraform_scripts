terraform {
  required_version = ">= 1.5.7"

  # Declare the cloud providers this configuration uses.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Select the AWS region
provider "aws" {
  region = "us-east-1"
}
