resource "aws_launch_configuration" "main" {
  name_prefix   = "Launch-template-"
  image_id      = data.aws_ami.amazonlinux.id
  instance_type = "t2.micro"
  # since we gave the ec2 SSM access, we can instead go to ssm, create new session and ssh to the browser from there
  # key_name = "main"
  user_data            = file("${path.module}/user-data.sh")
  security_groups      = [aws_security_group.private-SG.id]
  iam_instance_profile = aws_iam_instance_profile.main.name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name = "sg-group-main"

  min_size         = 1
  desired_capacity = 2
  max_size         = 4

  launch_configuration = aws_launch_configuration.main.name
  target_group_arns    = var.lb_target_group
  vpc_zone_identifier  = var.private_subnet_ids

  lifecycle {
    create_before_destroy = true
  }
}

# we don't use them since they are created from ASG
# resource "aws_instance" "private" {
#   count = 2
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t3.micro"
#   key_name = "main"
#   security_groups = [aws_security_group.private-SG.id]
#   subnet_id = aws_subnet.private[count.index].id
#   user_data = file("user-data.sh")

#   tags = {
#     Name = "private-instance-${count.index+1}"
#   }
# }
