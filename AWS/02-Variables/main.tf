terraform {
  # remote backend
  backend "s3" {
    bucket       = "devops-directive-tf-state"
    key          = "02-variables/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # in newer versions of the Terraform, there is no need to use the dynamo_db for locking the state file
  }

  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# local variables are reusable named expressions inside this module
locals {
  extra_tag = "extra-tag"
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ami_ssm_parameter
}

resource "aws_instance" "instance" {
  # these variables are added in variables.tf file
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
    # using local variable declared above
    ExtraTag = local.extra_tag
  }
}

# Provides an RDS instance resource. A DB instance is an isolated database environment in the cloud. A DB instance can contain multiple user-created databases
# Amazon RDS supports instance classes for the following use cases: General-purpose, Memory-optimized, Burstable Performance, and Optimized-reads
resource "aws_db_instance" "db_instance" {
  allocated_storage = 20
  storage_type      = "gp3"
  engine            = "postgres"
  engine_version    = "16"
  # on what EC2 instance will this RDB instance run on
  instance_class    = "db.t3.micro"
  db_name           = "mydb"
  # these variables are added in variables.tf file
  username            = var.db_user
  password            = var.db_pass
  # In aws_db_instance, this tells Terraform/AWS to skip creating a final RDS snapshot when the database instance is deleted
  # If you destroy this RDS instance, AWS will delete it immediately without preserving a final copy of the data, This is convenient for disposable/test databases, but it can cause data loss for production workloads 
  skip_final_snapshot = true
}
