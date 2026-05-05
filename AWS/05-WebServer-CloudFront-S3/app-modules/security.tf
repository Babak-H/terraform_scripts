resource "aws_security_group" "App_SG" {
  name        = "App_SG"
  description = "Allow web traffic into the server"
  vpc_id      = aws_vpc.my_vpc.id
}

# Incoming traffic to the SG
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.App_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# another Ingress security group rule, this one only for the SSH on port 22
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.App_SG.id  
  cidr_ipv4         = var.ssh_cidr  # personal ip address that is allowed to perform the SSH
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Outgoing traffic from the SG
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.App_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Generate an SSH key pair for the EC2 instance
resource "tls_private_key" "Web-key" {
  algorithm = var.ssh_policy
  rsa_bits  = var.ssh_policy == "RSA" ? 4096 : null
}

# create the public-key resouce 
resource "aws_key_pair" "App-Instance-Key" {
  key_name   = "Web-key"
  public_key = tls_private_key.Web-key.public_key_openssh
}

# save the private key as a file to local machine
resource "local_file" "Web-Key" {
  content         = tls_private_key.Web-key.private_key_pem
  filename        = var.key_file
  file_permission = "0600"
}
