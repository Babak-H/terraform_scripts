terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
      }

      kubernetes = {
        source = "hashicorp/kubernetes"
        version = "2.23.0"
      }
    }
    
    # save terraform state file (state.tfstate) in remote bucket instead of locally
    # block the public access for tge bucket
    # enable versioning for the bucket
    backend "s3" {
      bucket = "myapp-bucket"
      key = "myapp/state.tfstate"
      region = var.region
    }
}

provider "aws" {
    region = var.region
    profile = "default"
}

provider "kubernetes" {
   #  endpoint to connect to the EKS cluster
   host = data.aws_eks_cluster.myapp-cluster.endpoint
   # token that is needed for authentiction with the cluster
   token = data.aws_eks_cluster_auth.myapp-cluster.token
   # PEM-encoded root certificates bundle for TLS authentication
   # certificate_authority - Nested attribute containing certificate-authority-data for your cluster.
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority[0].data)
}