# create ec2 instance with user-data and security group
resource "aws_instance" "Web" {
  ami = var.ami
  instance_type = var.instance_type
  # count = 1
  subnet_id = aws_subnet.my_app-subnet.id
  key_name = "Web-key"
  security_groups = [aws_security_group.App_SG.id]
  # the userdata file should be in the 
  user_data = file("userdata.tpl")
}



