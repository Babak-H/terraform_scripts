terraform {
#   required_version = "~> 1.3.8"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0" # only versions from 4.0 to 4.99 are accepted here
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = "default"
}