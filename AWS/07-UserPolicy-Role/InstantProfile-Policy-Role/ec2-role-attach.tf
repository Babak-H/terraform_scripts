data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# create the role
resource "aws_iam_role" "ec2-assume-role" {
  name = "ec2-assume-role"
  # allow assuming role on ec2 (who can assume this role)
  assume_role_policy = file("${path.module}/ec2-assume-policy.json")
}

# create the policy that will be attached to a role (what can this role do)
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2-assume-role.id
  # allow everything on ec2
  policy = file("${path.module}/ec2-policy.json")
}

# an Iam instance profile passes an IAM role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-assume-role.name
}

# create ec2 instance and attach instance_profile to it
resource "aws_instance" "Web" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  # security group and vpc/subnet will be default
  tags = {
    Name = "my-ec2"
  }
}
