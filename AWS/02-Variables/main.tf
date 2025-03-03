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

# local variable
locals {
  extra_tag = "extra-tag"
}

resource "aws_instance" "instance" {
  # these variables are added in variables.tf file
  ami           = var.ami
  instance_type = var.instance_type

  tags = {
    Name     = var.instance_name
    # using local variable created before
    ExtraTag = local.extra_tag
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "postgres"
  engine_version      = "12.4"
  instance_class      = "db.t2.micro"
  name                = "mydb"
  # these variables are added in variables.tf file
  username            = var.db_user
  password            = var.db_pass
  skip_final_snapshot = true
}
