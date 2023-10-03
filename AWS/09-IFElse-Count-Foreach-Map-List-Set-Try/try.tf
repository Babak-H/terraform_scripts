# evaluates all of its argument expressions in turn and returns the result of the first one that does not produce any errors.
variable "example" {
  type = any
}

locals {
  example = try(
    [tostring(var.example)],
    tolist(var.example),
  )
}

# if first option in try() didn't work => go to second one
locals {
  raw_value = yamldecode(file("${path.module}/example.yaml"))
  normalized_value = {
    name   = tostring(try(local.raw_value.name, null))
    groups = try(local.raw_value.groups, [])
  }
}


