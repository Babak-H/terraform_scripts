variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-east-1"
}

# we use this list to create the two backend repos and images dynamically
variable "repository_list" {
  description = "List of repository names"
  type        = list(any)
  default     = ["backend", "frontend"]
}