# these are values for variables created in variables.tf file
instance_name = "hello-world"
ami           = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
instance_type = "t2.micro"

# since username and password are sensetive data, it is better to give them as input from cli
# also can be stored and retrieved from AWS SecretManager
# terraform apply -var"db_user=myuser" -var="db_pass=MySuperSecretPass"
