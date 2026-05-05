variable "region" {
  description = "Default AWS region."
  type        = string
  default     = "us-east-1"
}

variable "amazon_linux_ami_ssm_parameter" {
  description = "Public SSM parameter path for the Amazon Linux AMI ID to use for the EC2 instance."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "instance_user" {
  description = "EC2 instance username."
  type        = string
  default     = "ec2-user"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet."
  type        = string
  default     = "us-east-1a"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for app data."
  type        = string
}

variable "ssh_policy" {
  description = "Algorithm for the generated SSH key pair."
  type        = string
  default     = "RSA"
}

variable "key_file" {
  description = "Local filename for the generated private key used to SSH into the EC2 instance."
  type        = string
}

variable "ssh_cidr" {
  description = "Public IPv4 CIDR allowed to SSH to the EC2 instance, for example 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0))
    error_message = "ssh_cidr must be a valid IPv4 CIDR block."
  }
}
