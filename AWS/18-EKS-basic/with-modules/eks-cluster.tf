# this module will automatically create all needed roles and policies for the cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.1"

  cluster_name = "myapp-eks-cluster"
  cluster_version = "1.21"

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id = module.myapp-vpc.vpc_id

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true
  # normally it should be set to your own ip address only
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]


  eks_managed_node_group_defaults = {
    instance_types = ["t2.small"]
  }

  eks_managed_node_groups = {
    first = {
        min_size = 1
        max_size = 3
        desired_size = 2

        instance_types = ["t2.small"]
        capacity_type = "SPOT"
    }
    second = {
        min_size = 1
        max_size = 2
        desired_size = 1

        instance_types = ["t2.medium"]
        capacity_type = "SPOT"
    }
  }

  tags = {
    environment = "dev"
    application = "myapp"
  }
}