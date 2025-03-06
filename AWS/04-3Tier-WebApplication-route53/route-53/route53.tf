#######################################
# Route 53
#######################################

locals {
  template_body = templatefile("${path.module}/register-route53.json", {
    region = var.region
    accountId = data.aws_caller_identity.current.account_id
  })
}

resource "aws_cloud_formation_stack" "route53" {
  name = "${var.object_name}-route53"

  parameters = {
    InternalName = var.internal_name
    Name = var.dns_name
    AliasHostedZoneId = var.zone_id
    Domain = var.domain_name
    Alias = var.alias
    Type = var.type
  }

  template_body = locals.template_body
  tags = var.tags
}