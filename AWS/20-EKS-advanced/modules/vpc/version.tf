terraform {
  required_version = ">= 1.2.0"
  
  required_providers {
    aws = {
        source = "harshicorp/aws"
        version = "~> 4.16"
    }
  }
}