# 1. terraform init
# 2. terraform plan => to check what resources are already existing

provider "aws" {
    region = "us-east-1"
}

# 3. to import a resource we should first mention it, local name isn't important but needs correct cidr_block
# this works as a empty holder to keep the imported resource from AWS
resource "aws_vpc" "main" {
  cidr_block =  "10.0.0.0/18"

  tags = {
    Name = "main"
  }
}
/*
4. then we can import it via this command (for vpc). the id is available on the aws console 
we save the remote resource into the local one in terraform
terraform import aws_vpc.main vpc-<ID>
*/

# for subnet we need to mention the vpc-id, cidr block and the tag in placeholder to import the correct resource
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private"
  }
}
# 4. this process has to be run one-by-one for each resource 
# terraform import aws_subnet.public subnet-<ID>
# terraform import aws_subnet.private subnet-<id>

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}
# terraform import aws_internet_gateway.igw igw-<ID>

resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.igw]
}
# terraform import aws_eip.nat_eip <IP-ADDRESS>


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public.id

  tags = {
    Name = "nat"
  }
}
# terraform import aws_nat_gateway.nat nat-<ID>

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}
# terraform import aws_route_table.public rtb-<id>

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
# terraform import aws_route_table_association.public subnet-<ID>/rtb-<ID>

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
  }
}
# terraform import aws_route_table.private rtb-<ID>

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
# terraform import aws_route_table_association.private subnet-<ID>/rtb-<ID>

resource "aws_security_group" "nginx" {
  name = "nginx"
  description = "Access for Nginx"
  vpc_id = aws_vpc.main

  ingress {
    description = "web access"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# terraform import aws_security_group.nginx sg-<ID>

resource "aws_instance" "nginx" {
  ami = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.nginx.id]
  key_name = "devops"

  tags = {
    Name = "Nginx"
  }
}
# terraform import aws_instance.nginx i-<ID>

# 5. run terraform plan again to make sure there is nothing to build