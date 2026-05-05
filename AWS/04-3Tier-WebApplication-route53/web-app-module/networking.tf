# we are using the default vpc for our web app ,in case default vpc doesnt exist, will throw an error
# data: references exisitng resource in aws
data "aws_vpc" "default_vpc" {
  default = true
}

# default subnets inside the default vpc
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# Create a security group for the EC2 instances
resource "aws_security_group" "instances" {
  name        = "${var.app_name}-${var.environment_name}-instance-security-group"
  description = "Allow ALB traffic to app instances"
  vpc_id      = data.aws_vpc.default_vpc.id
}

# Allow HTTP traffic from the ALB to the instances
resource "aws_vpc_security_group_ingress_rule" "allow_http_from_alb" {
  security_group_id            = aws_security_group.instances.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

# Allow instances to reach the internet for package updates
# instances can access all ip addresses and all protocols for egress (outgoing traffic)
resource "aws_vpc_security_group_egress_rule" "allow_instances_all_outbound" {
  security_group_id = aws_security_group.instances.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# create ALB loadbalancer listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page (when address is not defined)
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# create a target group for our alb, to attach instances to it
resource "aws_lb_target_group" "instances" {
  name     = "${var.app_name}-${var.environment_name}-tg"
  port     = 8080
  protocol = "HTTP"
  # target group will also exist in our default vpc
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# attach ec2 instances 1,2 to the target group
resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_2.id
  port             = 8080
}

# forward all pathes that come into the loadbalancer into the target group
resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

# create security group for the loadbalancer (this is before data reaches the EC2 security group)
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment_name}-alb-security-group"
  description = "Allow public HTTP traffic to the ALB"
  vpc_id      = data.aws_vpc.default_vpc.id
}

# ALB SG Ingress Rule: Allow public HTTP traffic to the ALB (traffic will then reach ec2 security group)
resource "aws_vpc_security_group_ingress_rule" "allow_alb_http_inbound" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# ALB SG Egress Rule: Allow outbound traffic from the ALB to targets (traffic will come from ec2 security group)
resource "aws_vpc_security_group_egress_rule" "allow_alb_all_outbound" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# create the Application Load Balancer itself 
resource "aws_lb" "load_balancer" {
  name               = "${var.app_name}-${var.environment_name}-web-app-alb"
  load_balancer_type = "application"
  # associate alb with default subnets
  subnets            = data.aws_subnets.default_subnets.ids
  # attach loadbalancer security group to it
  security_groups    = [aws_security_group.alb.id]
}
