# This example shows how to call an existing module from the Terraform Registry

terraform {
  backend "s3" {
    bucket       = "devops-directive-tf-state"
    key          = "03-module/consul/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.18.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# here is how we call a child module:
module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "0.13.0"

  # pass variables from the parent module to child module
  hvn             = var.hcp_hvn
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  route_table_ids = var.route_table_ids
}
