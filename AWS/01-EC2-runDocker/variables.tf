variable "admin_cidr" {
  description = "Public IPv4 CIDR allowed to SSH to the EC2 instance, for example 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid IPv4 CIDR block, for example 203.0.113.10/32."
  }
}

variable "ssh_public_key" {
  description = "SSH public key content to register as the EC2 key pair, for example the contents of ~/.ssh/babak-key.pub"
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a valid OpenSSH public key string."
  }
}
