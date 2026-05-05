# these are all input variables we can use in the main.tf file 
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "ubuntu_ami_ssm_parameter" {
  description = "Public SSM parameter path for the Ubuntu AMI ID to use for the EC2 instance"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_user" {
  description = "Username for the database"
  type        = string
  default     = "foo"
}

variable "db_pass" {
  description = "Password for the database"
  type        = string
  # this means that the value for this variable will not be visible in the console log
  sensitive   = true
}
