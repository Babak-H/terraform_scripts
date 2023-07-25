 #Log export for Elastic Cloud
module "log_export" {
  source                 = "terraform.int.liveperson.net/LivePerson/log-router-sinks/google"
  destination_uri        = "pubsub.googleapis.com/projects/lpgprj-gss-p-ctrlog-gl-01/topics/us-n"
  filter                 = "logName=(\"projects/lpgprj-b2b-q-dbeng-us-1/logs/elastic\")"
  log_sink_name          = "els-logs-to-ctrlog-pubsub"
  parent_resource_id     = "lpgprj-b2b-q-dbeng-us-1"
  parent_resource_type   = "project"
  unique_writer_identity = true
  description            = "Route logs to centralized logging pubsub topic"
}

module "lp-service-account" {
  source  = "terraform.lpcloud.io/LivePerson/lp-service-account/google"
  version = "4.0.2"
  description = "SA for elasticsearch database"
  purpose = "comp-els"
  lp_context = var.lp_context
}

#Create CB cluster elastic search
module "elast-cb-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-8"
  node_count = 3
  app = "cb"
  dbtype = "els"
  dataDiskSize = 1000
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "els",
    env = "qa",
    app = "cb",
    cluster_name = "elast-cb-q-useast1"
    team-name = "datastores_engg"
  }
}

module "elast-cb-q-useast1-2" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 3
  app = "maya"
  dataDiskSize = 500
  # dbtype = "els"
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "els",
    env = "qa",
    app = "maya",
    cluster_name = "elast-maya-q-useast1"
    team-name = "datastores_engg"
  }
}

module "elast-cb-q-useast1-4" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 5
  app = "shared"
  dataDiskSize = 500
  dbtype = "els"
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "els",
    env = "qa",
    app = "shared",
    cluster_name = "elast-shared-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create CB cluster elastic search
module "elast-cb-q-useast1-3" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-8"
  node_count = 3
  app = "cbmain"
  dbtype = "els"
  dataDiskSize = 1000
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "els",
    env = "qa",
    app = "cbmain",
    cluster_name = "elast-cb-q-useast1"
    team-name = "datastores_engg"
  }
}
