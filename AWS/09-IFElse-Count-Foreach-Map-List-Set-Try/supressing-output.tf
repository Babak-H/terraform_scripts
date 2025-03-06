#  Suppressing Values in CLI Output
# An output can be marked as containing sensitive material using the optional sensitive argument:
output "db_password" {
  value       = aws_db_instance.db.password
  description = "The password for logging in to the database."
  sensitive   = true
}

# Terraform will hide values marked as sensitive in the messages from terraform plan and terraform apply
output "a" {
  value     = "secret"
  sensitive = true
}

######
Terraform will perform the following actions:

  # test_instance.x will be created
  + resource "test_instance" "x" {
      + some_attribute    = (sensitive value)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + out = (sensitive value)
