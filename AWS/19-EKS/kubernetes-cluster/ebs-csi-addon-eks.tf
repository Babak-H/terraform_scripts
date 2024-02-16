# installs EBS CSI Driver usking eks addon, only use this if you did not install the helm chart for it
resource "aws_eks_addon" "ebs_eks_addon" {
  # create the add-on when the polcy/role for it is created  
  depends_on = [ aws_iam_role_policy_attachment.ebs_csi_iam_role_policy_attach ]
  # which cluster to add it to
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_id
  # name of this addon (custom)
  addon_name = "aws-ebs-csi-driver"
  # her we give the role arn that contains the csi driver policy, it will be annotated to service account
  service_account_role_arn = aws_iam_role.ebs_csi_iam_role.arn
}

output "ebs_eks_addon_arn" {
  description = "EKS Addon - EBS CSI Driver ARN"
  value = aws_eks_addon.ebs_eks_addon.arn
}

output "ebs_eks_addon_id" {
  description = "EKS Addon - EBS CSI Driver ID"
  value = aws_eks_addon.ebs_eks_addon.id
}

# all the deployments and daemonsets for csi driver will be installed on kube-system namespace