# toset() turns list into a set
output "instance_publicdns" {
  description = "EC2 instance public dns"
  value = toset([for instance in aws_instance.myec2: instnace.public_dns])
}

# tomap() creates a map
output "instnace_publicdns_2" {
  value = tomap({for az, instnace in aws_instance.myec2: az => instance.public_dns})
}

# turn it into a list of only keys
output "instnace_publicdns_3" {
  value = keys({for az, instnace in aws_instance.myec2: az => instance.public_dns})
}
