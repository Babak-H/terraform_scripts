terraform {
  backend "s3" {
    bucket = "1066305-00i3-DTOOL-terraform-state"
    key = "test-s3-common-module/terraform.tfstate"
    kms_key_id = "arn:aws:kms:eu-west-2:9066220:key/b23bc365-832d"
    encrypt = true
    region = "eu-west-2"
    role_arn = "arn:aws:iam::0844352:role/pave/tfstatemanager/1066305-00i3-DTOOL-terraform-state-manager"
  }

  required_version = ">= 1.0.7"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.aws_assume_role_pave
  }
}