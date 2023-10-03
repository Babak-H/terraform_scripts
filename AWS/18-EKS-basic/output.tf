output "public_ip_of_demo_server" {
    value = aws_instance.demo-server.public_ip
}

output "private_ip_of_demo_server" {
    value = aws_instance.demo-server.private_ip
}