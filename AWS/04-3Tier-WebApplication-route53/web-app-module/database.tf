# Create a PostgreSQL database.
resource "aws_db_instance" "db_instance" {
  allocated_storage   = var.db_allocated_storage
  storage_type        = "gp3"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = var.db_instance_class
  db_name             = var.db_name
  username            = var.db_user
  password            = var.db_pass
  skip_final_snapshot = true
}
