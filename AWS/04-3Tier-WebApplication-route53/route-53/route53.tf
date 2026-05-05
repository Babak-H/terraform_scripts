#######################################
# Route 53
#######################################

locals {
  template_body = templatefile("${path.module}/register-route53.json", {
    region    = var.region
    accountId = data.aws_caller_identity.current.account_id
  })
}

data "aws_caller_identity" "current" {}

resource "aws_cloudformation_stack" "route53" {
  name = "${var.object_name}-route53"

  parameters = {
    InternalName      = var.internal_name
    Name              = var.dns_name
    AliasHostedZoneId = var.zone_id
    Domain            = var.domain_name
    Alias             = tostring(var.alias)
    Type              = var.type
  }

  template_body = local.template_body
  tags          = var.tags
}
