// endpoint is the address of accessing the cluster
output "endpoint" {
    value = aws_eks_cluster.eks.endpoint
}