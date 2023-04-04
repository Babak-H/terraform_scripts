# loadbalancer relatede resources

resource "aws_security_group" "load-balancer-SG" {
  name = "load-balancer-SG"
  description = "allow port 80 TCP inbound to ELB"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "http to elb"
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load-balancer-SG"
  }
}

resource "aws_lb" "main" {
  name = "main"
  internal = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer-SG.id]
  #  loadbalancer needs at least two different public subnets (two different AZs)
  subnets = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "main"
  port     = 80
  protocol = "HTTP"
  # target group will also exist in our default vpc
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port = "traffic-port"
  }
}

# we don't need this, since the ASG automatically attaches instances to target groups 
# resource "aws_lb_target_group_attachment" "main" {
#   count = length[aws_instance.private] # public
#   target_group_arn = aws_lb_target_group.main.arn
#   target_id        = aws_instance.private[count.index].id # public
#   port             = 80
# }

# forward incoming data from elb to target group
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}