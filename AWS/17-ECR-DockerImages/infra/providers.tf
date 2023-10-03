/*
a. create ECR repositries
b. create docker images (via address in the name, put them in correct repo inside ecr)

** if you change a tag or something else in "docker_registry_image" resource, terraform will destory and replace that resource
*/

terraform {
  required_providers {
    # here we have two provides
    # aws => to create the resources on aws cloud
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    # to create docker images locally
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# docker provider needs repository url, username, password to be able to push created images to the remote repo (here we use ecr)
provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
  registry_auth {
    address  = local.aws_ecr_url
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}