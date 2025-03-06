###################################
# GENERAL
###################################

variable "tags" {
  type = map(string)
  description = "a map of additional tags"
  default = {}
}

variable "internal_name" {
  type        = string
  description = "The Internal name to be used in the request"
}

variable "object_name" {
  type        = string
  description = ""
}

variable "region" {
  type        = string
  description = "AWS region to deploy resources in"
}

variable "dns_name" {
  type        = string
  description = "The DNS name to associate with the Object <name>.<domain>"
}

variable "zone_id" {
  type        = string
  description = "The ID of the Amazon Route 53-hosted zone name that is associated with the load balancer."
  default     = ""
}

variable "domain_name" {
  type        = string
  description = "The hosted zone domain e.g. eng.awsdev.my-corps.net"
}

variable "type" {
  type        = string
  description = "Type of route53 record, e.g. A, AAAA, CNAME"
}

variable "alias" {
  type        = bool
  description = "Whether this record should be an AWS Route 53 Alias"
}







