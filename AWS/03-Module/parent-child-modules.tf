#  the relationship between child module and parent module in terraform
# In Terraform, a parent module is the module that calls another module, while a child module is the module being called. The relationship between a child and parent module works as follows:

# Parent Module
# The root module (where Terraform is initially executed) acts as the parent module
# It can call one or more child modules using the module block
# The parent module passes input variables to the child module

# Child Module
# A child module is a separate Terraform configuration that is called by a parent module
# It defines input variables to accept values from the parent module
# It defines outputs that the parent module can use

# How They Work Together
# The parent module calls a child module by specifying its source (local directory, Git repo, Terraform Registry, etc.)
# The parent module passes variables to configure the child module
# The child module uses these variables to define resources
# The child module outputs values that can be used in the parent module


# Parent Module (main.tf)
module "network" {
  source      = "./modules/network"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}

# output of the network (child) module can be used as variable or output in the parent module
output "vpc_id" {
  value = module.network.vpc_id
}


# Child Module (modules/network/main.tf)
variable "vpc_cidr" {}
variable "subnet_cidr" {}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr
}

output "vpc_id" {
  value = aws_vpc.main.id
}

# Terraform Provider Configuration in Parent and Child Modules
# Terraform providers should be defined in a way that ensures proper inheritance and flexibility between the parent and child modules. Here’s how you should handle provider configurations:

# Define provider configurations in the root (Parent) module
# The best practice is to define providers in the parent module (root module)
# This ensures that the provider is initialized only once, avoiding redundant provider configurations
# The child modules automatically inherit the provider from the parent
# Terraform automatically passes the default provider configuration from the parent to child modules



# Root module example:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Avoid this in child modules unless necessary!
}

module "network" {
  source      = "./modules/network"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
}


# Child module provider declaration example:
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Avoid configuring provider blocks inside child modules unless the module is
# intentionally self-contained. Provider configurations in child modules make
# provider inheritance and resource cleanup harder.


# Using providers Argument for Explicit Provider Passing
# If a child module requires a different provider configuration, you can explicitly pass the provider to the module
#
# Example - Passing a Provider to a Child Module
provider "aws" {
  region = "us-east-1"
}

# we want to pass this to the child module, which has different region than the root module
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

module "network" {
  source      = "./modules/network"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"

  providers = {
    aws = aws
  }
}


module "network_eu" {
  source      = "./modules/network"
  vpc_cidr    = "192.168.0.0/16"
  subnet_cidr = "192.168.1.0/24"

  providers = {
    aws = aws.eu  # Explicitly using the `eu` provider alias
  }
}


# Multiple Providers in Child Modules
# If a child module requires multiple providers, you can define them in the parent and pass them using the providers argument.
# Inside the child module, use provider "aws" {} with alias to reference specific providers.

# In Parent module:
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

module "multi_region" {
  source = "./modules/multi_region"

  providers = {
    aws      = aws
    aws.eu   = aws.eu
  }
}

# In Child module:
resource "aws_vpc" "us" {
  provider   = aws
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "eu" {
  provider   = aws.eu
  cidr_block = "192.168.0.0/16"
}
