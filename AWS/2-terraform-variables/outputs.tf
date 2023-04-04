# these are the variables that can be used AFTER some item has been provisioned, can be used when creating other elements that might need it
output "instance_ip_addr" {
  value = aws_instance.instance.private_ip
}

output "db_instance_addr" {
  value = aws_db_instance.db_instance.address
}
