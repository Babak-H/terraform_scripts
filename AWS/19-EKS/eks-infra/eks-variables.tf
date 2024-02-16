variable "cluster_name" {
  description = "name of the eks cluster"
  type = string
  default = "eksdemo1"
}

variable "cluster_service_ipv4_cidr" {
  description = "service ipv4 cidr for the k8s cluster"
  type = string
  default = "172.20.0.0/16"
}

variable "cluster_version" {
  description = "k8s minor version to use for the eks cluster"
  type = string
  default = "1.27"
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type = bool
  default = false
}

variable "cluster_endpoint_public_access" {
  description = "ndicates whether or not the Amazon EKS public API server endpoint is enabled. When it's set to `false` ensure to have a proper private access with `cluster_endpoint_private_access = true`."
  type = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type = list(string)
  default = ["0.0.0.0/0"]
}