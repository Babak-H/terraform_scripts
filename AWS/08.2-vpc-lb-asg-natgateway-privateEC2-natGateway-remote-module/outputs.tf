#  our outputs should be same as the ones defined by the creator of this module
output "vpc_id" {
    description = "the id of the vpc"
    # module - module name - variable name
    value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
    description = "The CIDR block of the VPC"
    value = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "azs" {
  description = "A list of availability zones spefified as argument to this module"
  value       = module.vpc.azs
}

### bastion host 
output "ec2_bastion_public_instance_id" {
  description = "list of ids of the instance"
  value = module.ec2_public.id
}

output "ec2_bastion_public_ip" {
  description = "elastic ip of the bastion host instance"
  value = aws_eip.bastion_eip.public_ip
}
