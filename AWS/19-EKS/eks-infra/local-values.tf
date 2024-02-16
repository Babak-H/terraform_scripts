# local variables allow you to define complex logic when creating the values for variables
# in local variables you can also reference other values or variables
locals {
  owners = var.business_division
  environment = var.environment
  name = "${var.business_division}-${var.environment}"  # HR-dev
  # other way of doing it using other local values
  # name = "${local.owners}-${locals.environment}"
  
  common_tags = {
    owners = local.owners
    environment = local.environment
  }

  eks_cluster_name = "${local.name}-${var.cluster_name}"
}