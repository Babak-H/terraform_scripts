# create a role resource that we need to create an eks cluster
resource "aws_iam_role" "eks" {
  name = "${var.env}-${var.eks_name}-eks-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# attach policy to it that allows eks creation
resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks.name
}

# create the cluster!!
resource "aws_eks_cluster" "this" {
  name = "${var.env}-${var.eks_name}"
  version = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    # since we don't have vpn, it can be set to false for private access
    endpoint_private_access = false
    endpoint_public_access = true

    subnet_ids = var.subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}