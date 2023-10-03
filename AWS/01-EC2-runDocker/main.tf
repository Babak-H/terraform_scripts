# aws_vpc: the static name that can't be changed
# main : custom name for the vpc, can be whatever we want it to be, it will NOT show up in AWS
resource "aws_vpc" "babak-vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

# what resources we want to provision
resource "aws_subnet" "babak-subnet" {
  # static name for vpc => custom name for our vpc => our vpc's id
  vpc_id                  = aws_vpc.babak-vpc.id
  cidr_block              = "10.123.1.0/24"
  # Auto-assign IPV4 (for ec2 instances)
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "babak_gateway" {
  vpc_id = aws_vpc.babak-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "babak_public_rt" {
  vpc_id = aws_vpc.babak-vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.babak_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.babak_gateway.id
}

# this is same as explicit subnet association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.babak-subnet.id
  route_table_id = aws_route_table.babak_public_rt.id
}

# security group for EC2 instances
resource "aws_security_group" "babak-sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.babak-vpc.id

  # inbound rules
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["*****/32"] # personal ip address
  }

  # outbound rules
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # allow our public subnet to access open internet
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# this is the ssh key-pair we use to connect to our ec-2 instances
# the public-key will be uploaded to the "Key Pair" section under "EC2" => "Network and Security"
resource "aws_key_pair" "babak_auth" {
  key_name   = "babak-key"
  public_key = file("~/.ssh/babak-key.pub")
}

resource "aws_instance" "dev-node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.babak_ami.id
  key_name               = aws_key_pair.babak_auth.id
  vpc_security_group_ids = [aws_security_group.babak-sg.id]
  subnet_id              = aws_subnet.babak-subnet.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }
}


