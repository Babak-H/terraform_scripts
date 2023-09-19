terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0" # only versions from 4.0 to 4.99 are accepted here
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}