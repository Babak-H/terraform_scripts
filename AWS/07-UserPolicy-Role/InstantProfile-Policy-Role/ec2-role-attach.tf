# create the role
resource "aws_iam_role" "ec2-assume-role" {
  name = "ec2-assume-role"
  # allow assuming role on ec2
  assume_role_policy = "${file("ec2-assume-policy.json")}"
}

# create the policy that will be attached to a role
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2-assume-role.id
  # allow everything on ec2
  policy = "${file("ec2-policy.json")}"
}

# an Iam instance profile passes an IAM role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-assume-role.name
}

# create ec2 instance and attach instance_profile to it
resource "aws_instance" "Web" {
  ami = "ami-011899242bb902164"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  # security group and vpc/subnet will be default
  tags = {
    Name = "my-ec2"
  }
}