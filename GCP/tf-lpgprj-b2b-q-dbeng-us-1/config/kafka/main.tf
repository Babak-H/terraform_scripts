#Log export for Elastic Cloud
module "log_export" {
  source                 = "terraform.int.liveperson.net/LivePerson/log-router-sinks/google"
  destination_uri        = "pubsub.googleapis.com/projects/lpgprj-gss-p-ctrlog-gl-01/topics/us-n"
  filter                 = "logName=(\"projects/lpgprj-b2b-q-dbeng-us-1/logs/kafka\")"
  log_sink_name          = "kafka-logs-to-ctrlog-pubsub"
  parent_resource_id     = "lpgprj-b2b-q-dbeng-us-1"
  parent_resource_type   = "project"
  unique_writer_identity = true
  description            = "Route logs to centralized logging pubsub topic"
}

# Create service accounts for Kafka
module "lp-service-account" {
  source  = "terraform.lpcloud.io/LivePerson/lp-service-account/google"
  version = "4.0.2"
  description = "SA for kafka clusters"
  purpose = "comp-kfk"
  lp_context = var.lp_context
}

#Create CB cluster elastic search
module "kafka-bcb-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-8"
  node_count = 3
  app = "bcb"
  dbtype = "kfk"
  dataDiskSize = 500
  codeDiskSize = 200
  tags = ["kafka"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "kafka",
    env = "qa",
    app = "bcb",
    cluster_name = "kafka-bcb-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create CB cluster elastic search
module "zk-bcb-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  machine_type = "e2-standard-8"
  node_count = 3
  app = "bcb"
  dbtype = "zk"
  dataDiskSize = 250
  codeDiskSize = 200
  tags = ["zookeeper"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "zookeeper",
    env = "qa",
    app = "bcb",
    cluster_name = "kafka-bcb-q-useast1"
    team-name = "datastores_engg"
  }
}
