variable "region" {
  description = "default region"
  type = string
  default = "us-east-1"
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type = string
  default = "ami-0b5eea76982371e91"
}

variable "instance_type" {
  description = "ec2 instance type"
  type = string
  default = "t2.micro"
}

variable "instance_user" {
  description = "ec2 instance username"
  type = string
  default = "ec2-user"
}

variable "vpc_cidr" {
  description = "cidr block for the vpc"
  type = string
  default = "10.0.0.0/16"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "bucket_name" {
  description = "name of s3 bucket for app data"
  type        = string
  default = "babak2023s3bucketjan"
}

variable "s3-acl" {
  description = "ACL policy for s3 bucket"
  type        = string
  default = "public-read-write"
}

variable "ssh_policy" {
  description = "encryption type for the ssh key-pair"
  type = string
}

variable "key-file" {
  description = "name of the private key to ssh into ec2 instance"
  type = string
}
