module "lp-service-account" {
  source  = "terraform.lpcloud.io/LivePerson/lp-service-account/google"
  version = "4.0.2"
  description = "SA for redis database"
  purpose = "comp-redis"
  lp_context = var.lp_context
}

#Create Redisearch cluster for UMS
module "redis-ums-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "redis"
  region = "us-east1"
  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  machine_type = "e2-standard-4"
  node_count = 3
  app = "ums"
  dataDiskSize = 250
  service_account = module.lp-service-account.email
  tags = ["redis"]
  labels = {
    dbtype = "redis",
    env = "qa",
    app = "ums",
    cluster_name = "redis-ums-q-useast1"
    team-name = "datastores_engg"
  }
}

