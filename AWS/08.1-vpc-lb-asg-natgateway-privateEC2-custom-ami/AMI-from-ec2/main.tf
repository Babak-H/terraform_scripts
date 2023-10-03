# create an AMI from an existing EC2 instance

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.6.2"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# this will be available in the "owned by me" ami tab
resource "aws_ami_from_instance" "amibackup" {
  name = "EC2 AMI"
 # this can be output from another module or local dynamic value from current module
  source_instance_id = "i-XXXXXXXX"

  tags = {
    Name = "EC2 AMI"
    Environment = "DEV"
    Terraform = "True"
  }
}