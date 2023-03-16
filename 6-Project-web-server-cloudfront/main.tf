terraform {
  required_version = "~> 1.3.8"
  # declare what cloud provider we will use
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# select the default region
provider "aws" {
  region = "us-east-1"
}

# if we change name of module or add new modules, we need to re-initialize the terraform state
module "app_1" {
# import all the files from the web-app-module folder in here
  source = "./app-modules"

  ssh_policy = "RSA"
  key-file = "Web-Key.pem"
  bucket_name = "babak-bucket-2023-10-1"
}
