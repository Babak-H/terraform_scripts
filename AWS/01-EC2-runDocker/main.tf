# aws_vpc: the static name that can't be changed
# babak-vpc : custom name for the vpc, can be whatever we want it to be, it will NOT show up in AWS
resource "aws_vpc" "babak-vpc" {
  cidr_block           = "10.123.0.0/16"
  # Allows EC2 instances in the VPC to receive public DNS hostnames when they have public IPv4 addresses
  enable_dns_hostnames = true
   # Enables Amazon-provided DNS resolution inside the VPC. Instances can resolve DNS names, including AWS internal names and public domain names
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

# what resources we want to provision
resource "aws_subnet" "babak-subnet" {
  # static name for vpc => custom name for our vpc => our vpc's id
  vpc_id     = aws_vpc.babak-vpc.id
  cidr_block = "10.123.1.0/24"
  # Auto-assign public IPv4 addresses for instances launched in this public subnet
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "babak_gateway" {
  vpc_id = aws_vpc.babak-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "babak_public_rt" {
  vpc_id = aws_vpc.babak-vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

# this is like adding a route to the routeTable
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.babak_public_rt.id
  # any traffic whose destination doesn't match a more specific route will match this rule
  # send all outbound traffic destined for any IPv4 address to the Internet Gateway
  # this makes your subnet public by allowing EC2 instances to => Reach the Internet — instances can download packages, pull Docker images, etc, Receive traffic from the Internet — the Internet Gateway can route incoming traffic to your instances (subject to security group rules) 
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.babak_gateway.id
}

# this is same as explicit subnet association with public subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.babak-subnet.id
  route_table_id = aws_route_table.babak_public_rt.id
}

# security group for EC2 instances
resource "aws_security_group" "babak-sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.babak-vpc.id

  tags = {
    Name = "dev_sg"
  }
}

# Ingress (inbound Rules) for the security group
resource "aws_vpc_security_group_ingress_rule" "ingress_sg" {
  security_group_id = aws_security_group.babak-sg.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Egress (outbound rules) for the security group
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.babak-sg.id
  # allow our public subnet to access open internet
  cidr_ipv4         = "0.0.0.0/0"
  # all protocols are in this range
  ip_protocol       = "-1"
}

# this is the ssh key-pair we use to connect to our ec-2 instances
# The public key is uploaded to EC2 > Network & Security > Key Pairs
resource "aws_key_pair" "babak_auth" {
  key_name   = "babak-key"
  public_key = var.ssh_public_key   # file("~/.ssh/babak-key.pub")
}

# EC2 instance creation
resource "aws_instance" "dev-node" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  key_name               = aws_key_pair.babak_auth.key_name
  vpc_security_group_ids = [aws_security_group.babak-sg.id]
  subnet_id              = aws_subnet.babak-subnet.id
  user_data              = file("${path.module}/userdata.tpl")

  # configures the EC2 instance’s primary disk — the boot volume
  # It is the volume that contains the operating system, AWS attaches it as the instance’s root filesystem
  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }
}
