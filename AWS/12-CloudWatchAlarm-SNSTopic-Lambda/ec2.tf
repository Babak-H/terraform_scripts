# the instance that the alarm metrics will be based on
resource "aws_instance" "my_server" {
  ami = "ami-011899242bb902164"
  instance_type = "t3.micro"
  associate_public_ip_address = true
  tags = {
    Name = "public-instance-1"
  }
}