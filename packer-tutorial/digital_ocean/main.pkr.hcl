# this is the plugin that we define based on provider, can be also AWS or Azure,...
# https://developer.hashicorp.com/packer/plugins/builders/digitalocean
packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

locals {
  timestamp = formatdate("YYYY-MM",timestamp())
}

source "digitalocean" "this" {
    api_token = "${var.api_token}"
    droplet_name = "${var.droplet_name}-${local.timestamp}"
    image = "${var.image}"
    region = "${var.region}"
    size = "${var.size}"
    snapshot_name = "${var.snapshot_name}-${local.timestamp}"
    snapshot_regions = "${var.snapshot_regions}"
    #  this is used to ssh into the target platform and build the image there
    ssh_username = "${var.ssh_username}"
    tags = "${var.tags}"
}

build {
    sources = ["source.digitalocean.this"]
    provisioner "shell" {
        inline = [
            "groupadd -g 1001 ubuntu",
            "useradd ubuntu -m -g 1001 -u 1001 ",
            "apt-get update"
        ]
    }

    provisioner "shell" {
      script = "./bootstrap.sh"
    }
}
