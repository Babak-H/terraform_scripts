variable "aws_region" {
  description = "regions in whih aws will be created"
  type = string
  default = "us-east-1"
}

variable "environment" {
  description = "Environment variable used as a prefix"
  type = string
  default = "dev"
}

variable "business_division" {
  description = "Business division in the large organization"
  type = string
  default = "HR"
}