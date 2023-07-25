variable "instances" {
  type = list(any)
  description = "List of instances to be added to the load balancer"
}

variable "zone" {
  type = list(any)
}

variable "zones" {
  type = list(any)
  description = "List of zones to be added to the load balancer"
  default = ["us-east1-b", "us-east1-c", "us-east1-d"]
}

variable node_count {
  type = string
  default = 1
  description = "number of loadbalancers to be created"
}

variable "check_interval_sec" {
  type = number
  default = 20
}  

variable "timeout_sec" {
  type = number
  default = 5
}

variable "healthy_threshold" {
  type = number
  default = 1
}

variable "unhealthy_threshold" {
  type = number
  default = 3
}

variable "backend_timeout_sec" {
  type = number
  default = 10
}

variable "region" {
  type        = string
  default     = "us-east1"
  description = "Region where compute instances are created."
}

variable "subnetwork_project" {
  default     = "lpgprj-b2b-n-hostcc-us-01"
  type        = string
  description = "Subnet work shared by the project"
}

variable "vpc_network" {
  default     = "lpgvpc-h-b2b-npr-us-01"
  type        = string
  description = "VPC network for the project"
}

variable "type" {
  default = "itcp"
  type = string
  description = "internal or external loadbalancer and it's protocol"
}