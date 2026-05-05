# Use the latest Amazon Linux 2023 AMI in the selected region instead of a stale hard-coded AMI ID
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# The EC2 instance whose CPU utilization is monitored by the CloudWatch alarm
# since we do not mention here, it will be hosted on default VPC and default Subnet
resource "aws_instance" "my_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true

  tags = {
    Name = "public-instance-1"
  }
}
