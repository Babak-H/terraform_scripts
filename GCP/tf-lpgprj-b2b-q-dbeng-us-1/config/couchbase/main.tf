#Log export for couchbase Cloud into Elastic Cloud
module "log_export" {
  source                 = "terraform.int.liveperson.net/LivePerson/log-router-sinks/google"
  destination_uri        = "pubsub.googleapis.com/projects/lpgprj-gss-p-ctrlog-gl-01/topics/us-n"
  filter                 = "logName=(\"projects/lpgprj-b2b-q-dbeng-us-1/logs/couchbase\")"
  log_sink_name          = "couch-logs-to-ctrlog-pubsub"
  parent_resource_id     = "lpgprj-b2b-q-dbeng-us-1"
  parent_resource_type   = "project"
  unique_writer_identity = true
  description            = "Route logs to centralized logging pubsub topic"
}

module "lp-service-account" {
  source  = "terraform.lpcloud.io/LivePerson/lp-service-account/google"
  version = "4.0.2"
  description = "SA for couchbase database"
  purpose = "comp-couch"
  lp_context = var.lp_context
}

#Create VM instances for UMS cluster in QA Enterprise 7.1.4
module "couch-ums-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  zones  = ["us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-8"
  node_count = 6
  dbtype = "couch"
  app = "ums"
  dataDiskSize = 500
  codeDiskSize = 200
  BootdiskSize = 200
  tags = ["couchbase"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "couch",
    env = "qa",
    app = "ums",
    cluster_name = "couch-ums-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create VM instances for Cache cluster in QA
module "couch-cachece-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  zones  = ["us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-4"
  node_count = 4
  dbtype = "couch"
  app = "cache"
  dataDiskSize = 500
  codeDiskSize = 200
  tags = ["couchbase"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "couch",
    env = "qa",
    app = "cache",
    cluster_name = "couch-cachece-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create VM instances for Dynamic Actions and Webhooks cluster in QA
module "couch-dnace-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  zones  = ["us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-4"
  node_count = 4
  dbtype = "couch"
  app = "dna"
  dataDiskSize = 500
  codeDiskSize = 200
  tags = ["couchbase"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "couch",
    env = "qa",
    app = "dna",
    cluster_name = "couch-dnace-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create VM instances for LIKEDB cluster in QA
module "couch-likece-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  zones  = ["us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-4"
  node_count = 4
  dbtype = "couch"
  app = "like"
  dataDiskSize = 500
  codeDiskSize = 200
  tags = ["couchbase"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "couch",
    env = "qa",
    app = "like",
    cluster_name = "couch-likece-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create VM instances for COREAI cluster in QA
module "couch-coreaice-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  zones  = ["us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-4"
  node_count = 4
  dbtype = "couch"
  app = "core"
  dataDiskSize = 500
  codeDiskSize = 200
  tags = ["couchbase"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "couch",
    env = "qa",
    app = "coreai",
    cluster_name = "couch-coreaice-q-useast1"
    team-name = "datastores_engg"
  }
}

#Create VM instances for shared cluster in Non UMS Shared cluster 7.1.4
module "couch-shared2-q-useast1" {
  source = "../../modules/compute_instance"
  region = "us-east1"
  zones  = ["us-east1-b", "us-east1-c"]
  machine_type = "e2-standard-8"
  node_count = 6
  dbtype = "couch"
  app = "all"
  dataDiskSize = 500
  codeDiskSize = 200
  tags = ["couchbase"]
  service_account = module.lp-service-account.email
  labels = {
    dbtype = "couch",
    env = "qa",
    app = "shared",
    cluster_name = "couch-shared-q-useast1"
    team-name = "datastores_engg"
  }
}

