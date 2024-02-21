# create a kubernetes service account and annotate it with the role that allows reading s3 via openID
resource "kubernetes_service_account_v1" "irsa-demo-sa" {
  depends_on = [ aws_iam_role_policy_attachment.irsa-iam-role-policy-attach ]
  metadata {
    name = "irsa-demo-sa"
    namespace = "default" # var.serviceaccount_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa-iam-role.arn
    }
  }
}
