# this part will decrypt the encrypted user/pass via kms key
data "aws_kms_secrets" "creds" {
  secret {
    # name the decrypted file "db"
    name    = "db"
    # read it from this location
    payload = file("${path.module}/db-creds.yml.encrypted")
  }
}
# we get these values after decryption of the yaml file via kms key and save them in local variable named "db_creds"
locals {
  db_creds = yamldecode(data.aws_kms_secrets.creds.plaintext["db"])
}

resource "aws_db_instance" "mydb" {
  db_name = "mydb"
  engine = "postgres"
  engine_version = "15"
  instance_class = "db.t4g.micro"
  allocated_storage = 10

  publicly_accessible = true
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.public.name

  username = local.db_creds.username
  password = local.db_creds.password

#  use this in case of using environment variables
#  username = var.username
#  password = var.password
}