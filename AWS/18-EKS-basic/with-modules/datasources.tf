data "aws_availability_zones" "azs" {}
# query the aws resources based on this id and find the datasource eks cluster that matches it
data "aws_eks_cluster" "myapp-cluster" {
    name = module.eks.cluster_id
}
# Get an authentication token to communicate with an EKS cluster.
data "aws_eks_cluster_auth" "myapp-cluster" {
    name = module.eks.cluster_id
}