variable "hcp_hvn" {
  description = "HCP HVN object to connect to the AWS VPC, usually from an hcp_hvn resource or data source"
  type        = any
}

variable "vpc_id" {
  description = "AWS VPC ID to peer with the HCP HVN"
  type        = string
}

variable "subnet_ids" {
  description = "AWS subnet IDs whose CIDR blocks should be routable from HCP Consul"
  type        = list(string)
}

variable "route_table_ids" {
  description = "AWS route table IDs that need routes back to the HCP HVN"
  type        = list(string)
}
