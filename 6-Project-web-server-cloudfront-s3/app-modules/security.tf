resource "aws_security_group" "App_SG" {
  name = "App_SG"
  description = "allow web traffic into the server"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["******/0"]  # personal ip address
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# generate ssh key-pair
resource "tls_private_key" "Web-key" {
  algorithm = var.ssh_policy
}

# create the public-key resouce
resource "aws_key_pair" "App-Instance-Key" {
  key_name = "Web-key"
  public_key = tls_private_key.Web-key.public_key_openssh
}

# save the private key as a file to local machine
resource "local_file" "Web-Key" {
  content = tls_private_key.Web-key.private_key_pem
  filename = var.key-file
}