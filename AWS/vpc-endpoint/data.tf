data "aws_subnet" "vpc_subnets" {
    count = length(split(",", var.has_private_subnets == "true" ? join(",", flatten(module.core_resources.private_subnet_ids)) : join(",", flatten(module.core_resources.public_subnet_ids))))
    id    = var.has_private_subnets == "true" ? element(concat(flatten(module.core_resources.private_subnet_ids), [""]), count.index) : element(concat(flatten(module.core_resources.public_subnet_ids), [""]), count.index)
}

