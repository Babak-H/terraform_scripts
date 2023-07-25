#Log export for Cassandra Cloud into Elastic Cloud
module "log_export" {
  source                 = "terraform.int.liveperson.net/LivePerson/log-router-sinks/google"
  destination_uri        = "pubsub.googleapis.com/projects/lpgprj-gss-p-ctrlog-gl-01/topics/us-n"
  filter                 = "logName=(\"projects/lpgprj-b2b-q-dbeng-us-1/logs/cassandra\")"
  log_sink_name          = "cass-logs-to-ctrlog-pubsub"
  parent_resource_id     = "lpgprj-b2b-q-dbeng-us-1"
  parent_resource_type   = "project"
  unique_writer_identity = true
  description            = "Route logs to centralized logging pubsub topic"
}


module "lp-service-account" {
  source  = "terraform.lpcloud.io/LivePerson/lp-service-account/google"
  version = "4.0.2"
  description = "SA for cassandra database"
  purpose = "comp-cass"
  lp_context = var.lp_context
}

#Create Cassandra cluster for CB
module "cass-cb-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 3
  app = "cb"
  dataDiskSize = 250
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "cass",
    env = "qa",
    app = "cb",
    cluster_name = "cass-cb-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create Cassandra cluster for QA-CSDS-Cluster
module "cass-csds-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 3
  app = "csds"
  dbtype = "cass"
  dataDiskSize = 250
  tags = ["cassandra"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "cassandra",
    env = "qa",
    app = "csds",
    cluster_name = "cass-csds-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create Cassandra cluster for QA-CHEETAH-Cluster
module "cass-chetah-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 3
  app = "chetah"
  dbtype = "cass"
  dataDiskSize = 250
  tags = ["cassandra"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "cassandra",
    env = "qa",
    app = "chetah",
    cluster_name = "cass-chetah-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create Cassandra cluster for QA-REPORTING-Cluster- Elephant cluster
module "cass-rpt-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 6
  app = "rpt"
  dbtype = "cass"
  dataDiskSize = 250
  tags = ["cassandra"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "cassandra",
    env = "qa",
    app = "reporting",
    cluster_name = "cass-rpt-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create Cassandra cluster for QA-GateKeeper-Cluster
module "cass-gtk-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-4"
  node_count = 3
  app = "gtk"
  dbtype = "cass"
  dataDiskSize = 250
  tags = ["cassandra"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "cassandra",
    env = "qa",
    app = "gatekeper",
    cluster_name = "cass-gtk-q-useast1"
    team-name = "datastores_engg"
  }
}