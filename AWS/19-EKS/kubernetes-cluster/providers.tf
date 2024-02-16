provider "aws" {
  region = var.aws_region
}

# Retrieve information about an EKS Cluster Infrastructure.
data "aws_eks_cluster" "cluster" {
    name = data.terraform_remote_state.eks.outputs.cluster_id
}

# Get an authentication token to communicate with an EKS cluster.
# Uses IAM credentials from the AWS provider to generate a temporary token that is compatible with AWS IAM Authenticator authentication
data "aws_eks_cluster_auth" "cluster" {
    name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
  # these 3 values are needed for the kubernetes provider(the terraform) to be able to connect to our cluster
  host = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster_auth.cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster_auth.cluster.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.cluster.token
  }
}