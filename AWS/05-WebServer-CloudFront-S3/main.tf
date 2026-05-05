terraform {
  required_version = ">= 1.10.0"

  # Declare the cloud providers this configuration uses
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

variable "ssh_cidr" {
  description = "Public IPv4 CIDR allowed to SSH to the EC2 instance, for example 203.0.113.10/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0))
    error_message = "ssh_cidr must be a valid IPv4 CIDR block"
  }
}

# if we change name of module or add new modules, we need to re-initialize the terraform state
module "app_1" {
  # import all the files from the web-app-module folder in here
  source = "./app-modules"

  ssh_policy = "RSA"
  key_file   = "Web-Key.pem"
  ssh_cidr   = var.ssh_cidr

  bucket_name = "babak-bucket-2023-10-1"
}
