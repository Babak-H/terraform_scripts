terraform {
  # declare what cloud provider we will use
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# # select the default region
provider "aws" {
  region = "us-east-1"
}