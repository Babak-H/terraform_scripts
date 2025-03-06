##################################
# CREATE VPC ENDPOINT
##################################

locals {
  create_security_groups = split(",", aws_security_group.endpoint_security_group[0].id) # ## We create this list from the string so that we can do a compare 
  private_subnet_ids = join(",", flatten(module.core_resources.private_subnet_ids))
  public_subnet_ids = join(",", flatten(module.core_resources.public_subnet_ids))
  split = split(",", var.has_private_subnets == "true" ? local.private_subnet_ids ? local.public_subnet_ids)
}

# This is required to enable secrets manager Lambda rotation.
# This is not part of the initial XSphere or Core Pave.
resource "aws_vpc_endpoint" "Endpoint" {
  count = var.enabled == "true" ? 1 : 0
  vpc_id = module.core_resources.vpc_id
  service_name = "com.amazonaws.${var.is_privatelink == "true" ? "vpce." : ""}${var.region}.${var.aws_service}"
  vpc_endpoint_type = "Interface"
  subnet_ids = split(",", var.has_private_subnets == "true" ? join(",", flatten(module.core_resources.private_subnet_ids)) : join(",", flatten(module.core.resources.public_subnet_ids)))
  private_dns_enabled = var.is_privatelink == "true" ? "false" : "true"
  security_group_ids  = split(",", length(var.external_sg_groups) >= 1 ? join(",", var.external_sg_groups) : join(",", local.create_security_groups))
  tags = {
    "technical.posture" = var.has_private_subnets == "true" ? "private" : "public"
    "fin.res.chg.id" = var.fin_res_chg_id
    "sys.res.env"          = var.sys_res_env
    "dyn.res.env"          = var.dyn_res_env
    "dyn.res.appcomponent" = var.dyn_res_appcomponent
    "dyn.res.appname"      = var.dyn_res_appname
    "dyn.res.mon"          = var.dyn_res_mon
    "ami.build.id"         = var.ami_build_id
    "release.version"      = var.release_version
    "Name" = "${var.dyn_res_appname}-endpoint"
  }
}

##################################################################
# Create Security group
##################################################################
resource "aws_security_group" "endpoint_secuirty_group" {
  count = var.enabled == "true" ? 1 : 0
  name = "vpc_endpoint_securitygroup-dev-1"
  description = "endpoint-security-group for ${var.aws_service}"
  vpc_id = module.core_resources.vpc_id 

  ingress {
    # TLS (change to whatever ports you need)
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ for s in data.aws_subnet.vpc_subnets : s.cidr_block ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}