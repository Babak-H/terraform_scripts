locals {
  # construct the ecr url in the local variables to access it inside the providers.tf file, the output variables cant be used inside same module 
  aws_ecr_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}
