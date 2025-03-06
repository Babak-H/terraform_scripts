# module "create_vpc_endpoint" {
#     source = "../"
#     region = var.region
#     aws_service = "com.amazonaws.${var.region}.vpce"
#     seal_id = var.seal_id
#     deployment_id       = var.deployment_id
#     use_guid            = var.use_guid
#     environment         = "dshs"
#     has_private_subnets = var.has_private_subnets
#     is_privatelink      = var.is_privatelink
#     enabled             = var.enabled
#     external_sg_groups  = var.external_sg_groups
# }

module "core_resources" {
  source = "git::https://bitbucket.prd.mycorps.net/terra/terraform-aws-com-core-state.git?ref=v1.0.2"
  has_private_subnets = var.has_private_subnets
}