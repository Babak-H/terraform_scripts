data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ami_ssm_parameter
}

# create two ec2 instances
resource "aws_instance" "instance_1" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default_subnets.ids, 0)
  # attach the security group defined in networking.tf to the ec2 instance
  vpc_security_group_ids      = [aws_security_group.instances.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
              #!/bin/bash
              echo "Hello, World 1" > index.html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_instance" "instance_2" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default_subnets.ids, 1)
  vpc_security_group_ids      = [aws_security_group.instances.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
              #!/bin/bash
              echo "Hello, World 2" > index.html
              python3 -m http.server 8080 &
              EOF
}
