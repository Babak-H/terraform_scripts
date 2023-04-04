# create two ec2 instances
resource "aws_instance" "instance_1" {
  ami             = var.ami
  instance_type   = var.instance_type
  # security group for the ec2 instances, so that they can have inbound traffic on port 8080
  # it is created below in this file
  # this is list, because ec2 instances can have many security groups
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 1" > index.html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_instance" "instance_2" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 2" > index.html
              python3 -m http.server 8080 &
              EOF
}