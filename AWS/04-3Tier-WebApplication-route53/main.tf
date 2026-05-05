terraform {
  backend "s3" {
    bucket       = "devops-directive-tf-state"
    key          = "04-3tier-web-application-route53/web-app/terraform.tfstate"
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
  }
}

provider "aws" {
  region = "us-east-1"
}

# Terraform prompts for these sensitive variables if they are not provided
# will be prompted to type this variable
variable "db_pass_1" {
  description = "password for database #1"
  type        = string
  sensitive   = true
}

variable "db_pass_2" {
  description = "password for database #2"
  type        = string
  sensitive   = true
}

module "web_app_1" {
  # import all the files from the web-app-module folder in here
  source = "./web-app-module"

  # Input variables, These can also be provided through a terraform.tfvars file
  bucket_name      = "web-app-1-devops-directive-web-app-data"
  domain           = "devopsdeployed.com"
  app_name         = "web-app-1"
  environment_name = "production"
  instance_type    = "t2.small"
  create_dns_zone  = true
  db_name          = "webapp1db"
  db_user          = "foo"
  db_pass          = var.db_pass_1
}

# the second module instance of the same child module called "web-app-module"
module "web_app_2" {
  source = "./web-app-module"

  # Input Variables
  bucket_name      = "web-app-2-devops-directive-web-app-data"
  domain           = "anotherdevopsdeployed.com"
  app_name         = "web-app-2"
  environment_name = "production"
  instance_type    = "t2.small"
  create_dns_zone  = true
  db_name          = "webapp2db"
  db_user          = "bar"
  db_pass          = var.db_pass_2
}
