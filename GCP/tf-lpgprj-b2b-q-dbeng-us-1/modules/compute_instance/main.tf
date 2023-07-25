locals {
  subnet_key = var.region
}

variable "subnets" {
  default = {
    us-east1 = "lpgsne-b2b-npro-usea1-01",
    us-west1 = "lpgsne-b2b-npro-uswe1-01",
  }
}

variable "regions" {
  default = {
    us-east1 = "usea1",
    us-west1 = "uswe1",
  }
}

/* Provision Static IPs*/
resource "google_compute_address" "static_ip_address" {
  count        = var.node_count
  name         = format("lpgcen-%s-%s%s-%s-%d", var.env, var.dbtype, var.app, var.regions[local.subnet_key],count.index + 1)
  project      = var.project_id
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = "projects/${var.subnetwork_project}/regions/${var.region}/subnetworks/${var.subnets[local.subnet_key]}"

  lifecycle {
    ignore_changes = all
  }
}

/* Provision Persistent storage */
resource "google_compute_disk" "data_disk" {
  count   = var.node_count
  name    = format("lpgcen-%s-%s%s-%s-%ddata-disk%d", var.env, var.dbtype, var.app, var.regions[local.subnet_key],count.index + 1,count.index + 1)
  type    = var.diskType
  zone    = element(var.zones, count.index)
  size    = var.dataDiskSize
  project = var.project_id
  labels  = var.labels

  lifecycle {
    ignore_changes = all
  }
}

/* Provision Persistent storage */
resource "google_compute_disk" "code_disk" {
  count   = var.node_count
  name    = format("lpgcen-%s-%s%s-%s-%dcode-disk%d", var.env, var.dbtype, var.app, var.regions[local.subnet_key],count.index + 1,count.index + 1)
  type    = var.diskType
  zone    = element(var.zones, count.index)
  size    = var.codeDiskSize
  project = var.project_id
  labels  = var.labels

  lifecycle {
    ignore_changes = all
  }
}

/* Provision Compute instances with Static internal IP's and External Storage attached */
resource "google_compute_instance" "datastore_compute" {
  count        = var.node_count
  name         = format("lpgcen-%s-%s%s-%s-%d", var.env, var.dbtype, var.app, var.regions[local.subnet_key],count.index + 1)
  machine_type = var.machine_type
  zone         = element(var.zones, count.index)
  project      = var.project_id
  tags         = var.tags
  labels       = var.labels

  boot_disk {
    device_name = format("lpgcen-%s-%s%s-%s-%dboot-disk%d", var.env, var.dbtype, var.app, var.regions[local.subnet_key],count.index + 1,count.index + 1)
    initialize_params {
      image = var.image
      size = var.BootdiskSize
      type = var.BootdiskType
    }
  }
  attached_disk {
    source      = element(google_compute_disk.data_disk.*.self_link, count.index)
    device_name = element(google_compute_disk.data_disk.*.name, count.index)
  }
  attached_disk {
    source      = element(google_compute_disk.code_disk.*.self_link, count.index)
    device_name = element(google_compute_disk.code_disk.*.name, count.index)
  }

  network_interface {
    network    = "projects/${var.subnetwork_project}/global/networks/${var.vpc_network}"
    subnetwork = "projects/${var.subnetwork_project}/regions/${var.region}/subnetworks/${var.subnets[local.subnet_key]}"
    network_ip = element(google_compute_address.static_ip_address.*.address, count.index)
  }
  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }

  lifecycle {
    ignore_changes = all
  }
}
