variable "location" {
  default = "ap-south-1"
}

variable "os_name" {
  default = "ami-09ba48996007c8b50"
}

# TODO: change the key name
variable "key" {
  default = "rtp-03"
}

variable "instance_type" {
  default = "t2.small"
}

variable "vpc-cidr" {
  default = "10.10.0.0/16"
}

variable "subnet1-cidr" {
  default = "10.10.1.0/24"
}

variable "subnet2-cidr" {
  default = "10.10.2.0/24"
}

variable "subnet-az" {
  default = "ap-south-1a"
}

variable "subnet-2-az" {
  default = "ap-south-1b"
}





