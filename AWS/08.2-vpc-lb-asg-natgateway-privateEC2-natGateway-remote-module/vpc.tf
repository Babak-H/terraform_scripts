# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones?lang=typescript
data "aws_availability_zones" "available" {
  state = "available"
  # exclude_names = ["us-east-1a", "us-east-1b"]
}

# create vpc using an exisitng module from terraform cloud\
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # for public modules always use specific version, so it won't break if something chagnes in future versions
  version = "2.78.0"

  # vpc basic details
  name = "${local.name}-${var.vpc_name}"
  cidr = var.vpc_cidr_block
  # azs             = var.vpc_availability_zone
  azs = data.aws_availability_zones.available.names
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets  

  # database Subnets
  database_subnets = var.vpc_database_subnets
  create_database_subnet_group = var.vpc_create_database_subnet_group
  create_database_subnet_route_table = var.vpc_create_database_subnet_route_table

  # NAT gatway for private subnets, it will automatically be associated with private subnets
  # it will also create elastic ip for the nat gateway
  enable_nat_gateway = var.vpc_enable_nat_gateway 
  single_nat_gateway = var.vpc_single_nat_gateway # is false, it will create one natgateway for each AZ

  # VPC DNS parameters
  /*
  If both attributes are enabled, an instance launched into the VPC receives a public DNS hostname 
  if it is assigned a public IPv4 address or an Elastic IP address at creation.
  */
   enable_dns_hostnames = true
   enable_dns_support = true

   # Tags
   public_subnet_tags = {
    Type = "public-subnets"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
   }

   private_subnet_tags = {
    Type = "private-subnets"
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
   }

   database_subnet_tags = {
    Type = "database-subnets"
   }

  tags = local.common_tags
  vpc_tags = local.common_tags

/* it will automatically create internet gateway, 
    route tables for private and public subnets 
    routes for private and public subnets
    association for routes to respective route tables
    association private route table to private subnet
    association public route table to public subnet */
}