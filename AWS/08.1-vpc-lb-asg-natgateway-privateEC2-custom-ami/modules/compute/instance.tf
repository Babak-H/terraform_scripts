resource "aws_security_group" "public-SG" {
  name = "public-SG"
  description = "public security group"
  vpc_id = var.vpc_id

  ingress {
    description = "browse web from my personal IP"
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["89.64.94.66/32"] 
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-SG"
  }
}

resource "aws_security_group" "private-SG" {
  name = "private-SG"
  description = "private security group"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP from loadbalancer"
    protocol = "tcp"
    from_port = 80
    to_port = 80
    security_groups = var.security_groups_private
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-SG"
  }
}


resource "aws_instance" "public" {
  count = 1
  
  ami           = data.aws_ami.amazonlinux.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  security_groups = [aws_security_group.public-SG.id]
  subnet_id = var.public_subnet_ids[count.index]

  tags = {
    Name = "public-instance-${count.index+1}"
  }
}

