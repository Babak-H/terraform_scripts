# ========= for ====================================================

variable "vpcs" {
    description = "a list of VPCs"
    default = ["main", "database", "client"]
}

output "new_vpcs" {
  value = [for vpc in var.vpcs : title(vpc)]
}

output "new_v2_vpcs" {
  value = [for vpc in var.vpcs : title(vpc) if length(vpc) < 5]
}


variable "my_vpcs" {
    default = {
        main = "main vpc"
        database = "vpc for database"
    }
}

# map to list
output "my_vpcs" {
# [for <KEY>, <VALUE> in <MAP> : <OUTPUT>]
  value = [for name, desc in var.my_vpcs : "${name} is the ${desc}"]
}

output "vpc_index" {
    value = "%{for vpc in var.vpcs}${vpc}, %{endfor}"

    # vpcs_index = "(0) main, (1) database, (2) client,"
}