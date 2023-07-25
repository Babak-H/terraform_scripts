#Log export for MySQL into Elastic Cloud
module "log_export" {
  source                 = "terraform.int.liveperson.net/LivePerson/log-router-sinks/google"
  destination_uri        = "pubsub.googleapis.com/projects/lpgprj-gss-p-ctrlog-gl-01/topics/us-n"
  filter                 = "logName=(\"projects/lpgprj-b2b-q-dbeng-us-1/logs/mysql-error.log\" OR \"projects/lpgprj-b2b-q-dbeng-us-1/logs/cloudsql.googleapis.com%2Fmysql.err\") AND resource.type=(\"gce_instance\" OR \"cloudsql_database\")"
  log_sink_name          = "mysql-logs-to-ctrlog-pubsub"
  parent_resource_id     = "lpgprj-b2b-q-dbeng-us-1"
  parent_resource_type   = "project"
  unique_writer_identity = true
  description            = "Route logs to centralized logging pubsub topic"
}

module "lp-service-account" {
  source  = "terraform.lpcloud.io/LivePerson/lp-service-account/google"
  version = "4.0.2"
  description = "SA for MySQL database"
  purpose = "comp-mysql"
  lp_context = var.lp_context
}

#Create MySQL QA cluster for AA
module "mysql-aa-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  machine_type = "e2-standard-2"
  node_count = 2
  app = "aa"
  dataDiskSize = 300
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "aa",
    cluster_name = "mysql-aa-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create MySQL QA cluster for Shared AA
module "mysql-sharedaa-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-c", "us-east1-d", "us-east1-b"]
  machine_type = "e2-standard-2"
  node_count = 1
  app = "shdaa"
  dataDiskSize = 250
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "sharedaa",
    cluster_name = "mysql-sharedaa-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create MySQL QA cluster for MSTR
module "mysql-mstr-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-d", "us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-2"
  node_count = 1
  app = "mstr"
  dataDiskSize = 250
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "mstr",
    cluster_name = "mysql-mstr-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create MySQL QA cluster for WhatsApp
module "mysql-whatsapp-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  machine_type = "e2-standard-2"
  node_count = 1
  app = "whapp"
  dataDiskSize = 250
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "whatsapp",
    cluster_name = "mysql-whatsapp-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create Orchestrator cluster for QA environment
module "mysql-orch-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  machine_type = "e2-standard-2"
  node_count = 3
  app = "orch"
  dataDiskSize = 50
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "orch",
    cluster_name = "mysql-orch-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create ProxySQL cluster 1 for QA environment
module "mysql-proxysql1-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  machine_type = "e2-standard-2"
  node_count = 2
  app = "prxy1"
  dataDiskSize = 80
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "proxysql1",
    cluster_name = "mysql-proxysql1-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create PMM Server for non-prod environment
module "mysql-pmm-q-useast1" {
  source = "../../modules/compute_instance"
  dbtype = "mysql"
  region = "us-east1"
  zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  machine_type = "e2-standard-2"
  node_count = 1
  app = "pmm"
  dataDiskSize = 250
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "mysql",
    env = "qa",
    app = "pmm",
    cluster_name = "mysql-pmm-q-useast1"
    team-name = "datastores_engg"
  }
}

module "loadbalancer-uig-proxysql-q-useast1" {
  source = "../../modules/uig_loadbalancer"
  instances = module.mysql-proxysql1-q-useast1.compute_instances_id
  zone = module.mysql-proxysql1-q-useast1.compute_instances_zone
}

