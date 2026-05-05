# General variables.
variable "region" {
  description = "Default AWS region."
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name used in resource names and tags."
  type        = string
}

variable "environment_name" {
  description = "Environment name, for example production, staging, or dev."
  type        = string
}

# EC2 variables
variable "ubuntu_ami_ssm_parameter" {
  description = "Public SSM parameter path for the Ubuntu AMI ID to use for EC2 instances."
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

# S3 variables.
variable "bucket_name" {
  description = "Name of the S3 bucket for app data."
  type        = string
}

# Route 53 variables.
variable "domain" {
  description = "Domain for the website."
  type        = string
}

variable "create_dns_zone" {
  description = "Whether to create a new Route 53 hosted zone instead of using an existing one."
  type        = bool
  default     = false
}

# RDS variables
variable "db_name" {
  description = "Database name."
  type        = string
}

variable "db_user" {
  description = "Database username."
  type        = string
}

variable "db_pass" {
  description = "Database password."
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated database storage in GiB."
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t3.micro"
}
