resource "aws_eks_cluster" "eks_cluster" {
  name = local.eks_cluster_name
  role_arn = aws_iam_role.eks_master_role.arn
  version = var.cluster_version

  vpc_config {
    # the cluster itself (some worker nodes and elastic NICs) will be created in the public subnet
    subnet_ids = module.vpc.public_subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access = var.cluster_endpoint_public_access
    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }

  kubernetes_network_config {
    # The CIDR block to assign Kubernetes pod and service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }

  # enable eks cluster control plane logging, visible on cloudWatch
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}