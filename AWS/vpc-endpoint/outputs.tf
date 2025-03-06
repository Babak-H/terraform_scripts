output "id" {
    value = aws_vpc_endpoint.Endpoint.*.id[0]
}

output "dns_entry" {
    description = "Return 'dns_entry' map, to get a value use for example: lookup(module.<module_name>.dns_entry[0], 'dns_name')"
    value = aws_vpc_endpoint.Endpoint.*.dns_entry[0]
}