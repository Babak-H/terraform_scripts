# in this file we use an already existing module from Harshicorp itself in our application
### REPO: https://github.com/hashicorp/terraform-aws-consul

terraform {
  backend "s3" {
    bucket         = "devops-directive-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

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

module "consul" {
  source = "git@github.com:hashicorp/terraform-aws-consul.git"
}
