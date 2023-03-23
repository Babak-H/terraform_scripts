#  each module has its own variables.tf and outputs.tf file, this way we can share values between them
module "networking" {
  source = "./modules/networking"

  public_cidr = ["10.0.0.0/24", "10.0.1.0/24"]
  private_cidr = ["10.0.2.0/24", "10.0.3.0/24"]
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id = module.networking.vpc_id
  security_groups_private = module.networking.security_groups_private
  lb_target_group = module.networking.lb_target_groups
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids = module.networking.public_subnet_ids
}
