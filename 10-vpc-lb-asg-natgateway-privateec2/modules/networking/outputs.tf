output "public_subnet_ids" {
    value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
    value = aws_subnet.private[*].id
}

output "load_balancer_url" {
    value = aws_lb.main.dns_name
}

output "vpc_id" {
    value = aws_vpc.main.id
}

output "security_groups_private" {
  value = [aws_security_group.load-balancer-SG.id]
}

output "lb_target_groups" {
    value = [aws_lb_target_group.main.arn]
}