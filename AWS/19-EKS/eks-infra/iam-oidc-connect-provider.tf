# go to AWS console -> IAM management -> identity providers -> oidc should exist


# use this data source to lookup information about the current aws partition
# the dns suffix of aws servers
data "aws_partition" "current" {}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  # A list of client IDs (also known as audiences). When a mobile or web app registers with an OpenID Connect provider, they establish a value that identifies the applicatio
  client_id_list = ["sts.${data.aws_partition.current.dns_suffix}"]
  
  # A list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s
  thumbprint_list = [var.eks_oidc_root_ca_thumbprint]
  
  # The URL of the identity provider. Corresponds to the iss claim.
  # this url responds to the openID link that was automatically generated when we created the EKS cluster
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = merge(
    {
        Name = "${var.cluster_name}-eks-irsa"
    },
    local.common_tags
  )
}

output "aws_iam_openid_connect_provider_arn" {
  description = "AWS IAM openID Connect Provider ARN"
  value = aws_iam_openid_connect_provider.oidc_provider.arn
}

# Extract OIDC Provider from OIDC Provider ARN
locals {
    aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.oidc_provider.arn}"), 1)
}

output "aws_iam_openid_connect_provider_extract_from_arn" {
  description = "AWS IAM Open ID Connect Provider extract from ARN"
  value = local.aws_iam_oidc_connect_provider_extract_from_arn
}


# Sample Outputs for Reference
/*
aws_iam_openid_connect_provider_arn = "arn:aws:iam::180789647333:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/A9DED4A4FA341C2A5D985A260650F232"
aws_iam_openid_connect_provider_extract_from_arn = "oidc.eks.us-east-1.amazonaws.com/id/A9DED4A4FA341C2A5D985A260650F232"
*/