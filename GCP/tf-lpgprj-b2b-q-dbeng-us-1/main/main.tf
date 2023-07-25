module "computeInstance" {
  source = "../config"
  lp_context = var.lp_context
}


module "lp_project_apis" {
  source  = "terraform.int.liveperson.net/LivePerson/lp-project-apis/google"
  version = "4.2.0"
  lp_context = var.lp_context
  api_urls = [
    "artifactregistry.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
  ]
}
