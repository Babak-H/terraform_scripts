resource "aws_iam_role" "irsa-iam-role" {
  name = "${data.terraform_remote_state.eks.outputs.cluster_id}-irsa-iam-role"
  # in this role allow assuming role identity via openid provider for a kubernetes service account 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn}"
        }
        Condition = {
          StringEquals = {
            # service account in default namespace
            # service account name is "irsa-demo-sa"            
            "${data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:default:irsa-demo-sa"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "${data.terraform_remote_state.eks.outputs.cluster_id}-irsa-iam-role"
  }
}

# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "irsa-iam-role-policy-attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role = aws_iam_role.irsa-iam-role.name
}

output "irsa-iam-role-arn" {
  description = "IRSA IAM Role ARN"
  value = aws_iam_role.irsa-iam-role.arn
}