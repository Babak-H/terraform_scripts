variable "api_token" {
    description = "y digital ocean token"
    type = string
    default = env("DIGITALOCEAN_TOKEN")
}

variable "droplet_name" {
    description = "name of droplet"
    type = string
    default = "ubuntu-nginx-test"
}

variable "image" {
    description = "image for the packer"
    type = string
    default = "ubuntu-20-04-x64"
}

variable "region" {
    description = "desired region"
    type = string
    default = "nyc1"
}

variable "size" {
    description = "desired cpu and ram size for droplet"
    type = string
    default = "s-1vcpu-1gb-amd"
}

variable "snapshot_name" {
    description = "ubuntu-nginx-std"
    type = string
    default = "ubuntu-nginx-std-1"
}

variable "snapshot_regions" {
    type = list(string)
    default = ["nyc1", "nyc3"]
}

variable "ssh_username" {
    type = string
    default = "root"
}

variable "tags" {
    description = "my tags"
    type = list(string)
    default = ["dev", "packer", "ubuntu"]
}


