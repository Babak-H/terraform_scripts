# security group for public bastion host
# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
module "public_bastion_sg" {
    source = "terraform-aws-modules/security-group/aws"
    version = "5.1.0"

    name = "${local.name}-public-bastion-sg"
    description = "security group for SSH port open for all IPv4, egress for all ports"
    vpc_id = module.vpc.vpc_id

    # Ingress rules and cidr range
    ingress_rules = ["ssh-tcp"]
    ingress_cidr_blocks = ["0.0.0.0/0"]

    # egress
    egress_rules = ["all-all"]

    tags = local.common_tags
}

module "ec2_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name = "${local.name}-BastionHost"

  ami = data.aws_ami.amzlinux2.id
  instance_type = var.instance_type
  key_name = var.instance_keypair
  monitoring = false
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.public_bastion_sg.security_group_id]

  tags = local.common_tags
}

# elastic ip for the bastion host instance
resource "aws_eip" "bastion_eip" {
  # we need the igw from vpc module to exist before we create the eip for bastion host
  depends_on = [module.ec2_public, module.vpc]

  instance = module.ec2_public.id
  # indicates if the eip is for use inside a vpc
  # domain = true 
  tags = local.common_tags
}

#### provisioners ###
resource "null_resource" "copy_ec2_keys" {
  depends_on = [module.ec2_public, aws_eip.bastion_eip]
  # connection block for provisioners to connect to EC2 instance
# terraform is going to connect to bastion host instance via ssh with the exisitng ssh key-pair and as "ec2-user" username
  connection {
    type = "ssh"
    host = aws_eip.bastion_eip.public_ip
    user = "ec2-user"
    password = ""
    private_key = file("private-key/eks-terraform-key.pem")
  }

  # since we want to ssh from bastion host to other machines inside the vpc (in private subnets) we need to have the ssh key-pair inside it, so we copy it from our machine to it
  provisioner "file" {
    source = "private-key/eks-terraform-key.pem"
    destination = "/tmp/eks-terraform-key.pem"
  }
  
  # to make it work, we have to limit the access on this file to read-only, we use remote-exec provisioner to run commands inside the machine
  provisioner "remote-exec" {
    inline = [ "sudo chmod 400 /tmp/eks-terraform-key.pem" ]
  }
}
