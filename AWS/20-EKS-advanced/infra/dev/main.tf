provider "aws" {
    region = "us-east-1"
}

terraform {
    backend "local" {
      path = "infra/dev/vpc/terraform.tfstate"
    }
}

module "vpc" {
  source = "../../modules/vpc"

  env = var.env
  azs = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets = ["10.0.64.0/19", "10.0.96.0/19"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/dev-demo" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/dev-demo" = "owned" 
  }
}

module "eks" {
  source = "../../modules/eks"

  eks_name   = "demo"
  eks_version = "1.26"
  env        = var.env
  subnet_ids = module.vpc.private_subnet_ids
  node_group = {
    general = {
      capacity_type = "ON_DEMAND"
      instance_types = ["t2.micro"]
      scaling_config = {
        desired_size = 1
        max_size = 10
        min_size = 0
      }
    }
  }
}

module "k8-addons" {
  source = "../../modules/k8-addons"

  cluster_autoscaler_helm_verion = "9.28.0"
  enable_cluster_autoscaler = true
  env                            = var.env
  eks_name                       = module.eks.eks_name
  openid_provider_arn            = module.eks.openid_provider_arn
}