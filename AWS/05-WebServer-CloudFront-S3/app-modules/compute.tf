data "aws_ssm_parameter" "amazon_linux_ami" {
  name = var.amazon_linux_ami_ssm_parameter
}

# create ec2 instance with user-data and security group
resource "aws_instance" "Web" {
  ami                         = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.my_app-subnet.id
  key_name                    = aws_key_pair.App-Instance-Key.key_name
  vpc_security_group_ids      = [aws_security_group.App_SG.id]
  associate_public_ip_address = true
  # the userdata file should be in the root module level
  user_data                   = file("${path.root}/userdata.tpl")
}
