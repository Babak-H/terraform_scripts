module "cassandra_resources" {
  source = "./cassandra"
  lp_context = var.lp_context
}

module "elastic_resources" {
  source = "./elastic"
  lp_context = var.lp_context
}

module "couchbase_resources" {
  source = "./couchbase"
  lp_context = var.lp_context
}

module "mysql_resources" {
  source = "./mysql"
  lp_context = var.lp_context
}

module "kafka_resources" {
  source = "./kafka"
  lp_context = var.lp_context
}

module "redis_resources" {
  source = "./redis"
  lp_context = var.lp_context
}
