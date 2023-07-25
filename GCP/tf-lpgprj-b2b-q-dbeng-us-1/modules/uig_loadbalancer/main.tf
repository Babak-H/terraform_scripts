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

// unmanaged instance groups, one for each zone.  [element(var.instances, count.index)]
resource "google_compute_instance_group" "unmanaged-groups" {
  count       = length(var.zone)
  name        = format("lpguig-%s-%d", var.regions[local.subnet_key], count.index + 1)
  description = "Unmanaged instance group"
  zone        = element(var.zone, count.index)
  instances   = [element(var.instances, count.index)]
  network     = "projects/${var.subnetwork_project}/global/networks/${var.vpc_network}"
}

// compute group health check with health check port 34071 for tcp
resource "google_compute_region_health_check" "health_check" {
  count       = var.node_count
  name        = format("lpghc-%s-%d", var.regions[local.subnet_key], count.index + 1)
  region = var.region
  check_interval_sec = var.check_interval_sec
  timeout_sec        = var.timeout_sec
  healthy_threshold  = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold
  tcp_health_check {
    port = "34071"
  }
}

// backend service for the load balancer to attach the uig to it, we loop through all uigs
resource "google_compute_region_backend_service" "backend_service" {
  count = var.node_count
  name        = format("lpgbs-%s-%s-%d", var.type, var.regions[local.subnet_key], count.index + 1)
  region      = var.region 
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks = [
    google_compute_region_health_check.health_check[count.index].self_link,
  ]
  dynamic "backend" {
    for_each = google_compute_instance_group.unmanaged-groups.*.self_link
    content {
      group = backend.value
    }
  }  
}

// frontend configuration for the load balancer
resource "google_compute_forwarding_rule" "forwarding_rule" {
  count = var.node_count
  // lpglb-ihttps-usea1-01
  name        = format("lpglb-%s-%s-%d", var.type, var.regions[local.subnet_key], count.index + 1)
  backend_service = google_compute_region_backend_service.backend_service[count.index].id
  region      = var.region
  ip_protocol = "TCP"
  description = "Forwarding rule"
  ports  = ["34071"]
  allow_global_access   = false
  load_balancing_scheme = "INTERNAL"
  network    = "projects/${var.subnetwork_project}/global/networks/${var.vpc_network}"
  subnetwork = "projects/${var.subnetwork_project}/regions/${var.region}/subnetworks/${var.subnets[local.subnet_key]}"
}
