# these are values for variables created in variables.tf file
instance_name = "hello-world"
instance_type = "t2.micro"

# Since database credentials are sensitive, pass them through CLI flags, TF_VAR_* environment variables, CI/CD secrets, or AWS Secrets Manager
# Example:
# terraform apply -var="db_user=myuser" -var="db_pass=MySuperSecretPass"
