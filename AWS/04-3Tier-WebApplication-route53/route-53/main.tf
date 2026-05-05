terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# here we want to have a different region than the main region of the Parent/root module
provider "aws" {
  region = "eu-west-1"
}
