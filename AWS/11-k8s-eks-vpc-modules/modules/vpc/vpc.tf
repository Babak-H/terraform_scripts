# for EKS, your VPC must have dns hostname and dns resolution support.
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  # required for EKS cluster
  enable_dns_support = true
  enable_dns_hostname = true

  tags = {
    Name = "${var.env}-main"
  }
}