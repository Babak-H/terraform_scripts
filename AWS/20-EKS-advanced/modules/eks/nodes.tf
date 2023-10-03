resource "aws_eks_node_group" "this" {
  for_each = var.node_group
  # attach all node groups to the cluster
  cluster_name = aws_eks_cluster.this.name
  # name of each node group
  node_group_name = each.key
  # attach the prevoiusly created iam role to each node group
  node_role_arn = aws_iam_role.nodes.arn

  subnet_ids = var.subnet_ids
  # instance family and size for each node group
  capacity_type = each.value.capacity_type
  instance_type = each.value.instance_types

  # autoscaling values for internal auto-scaler of each node group
  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size = each.value.scaling_config.max_size
    min_size = each.value.scaling_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = each.key
  }

  depends_on = [aws_iam_role_policy_attachment.nodes]
}