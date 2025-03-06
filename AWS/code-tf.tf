terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }
}
# aws_kms_alias
# Provides an alias for a KMS customer master key. AWS Console enforces 1-to-1 mapping between aliases & keys, but API (hence Terraform too) allows you to create as many aliases as the account limits allow you
resource "aws_kms_key" "a" {}

resource "aws_kms_alias" "a" {
  name = "alias/my-key-alias"
  target_key_id = aws_kms_key.a.key_id
}

#============================================

# aws_availability_zones
# The Availability Zones data source allows access to the list of AWS Availability Zones which can be accessed by an AWS account within the region configured in the provider
data "aws_availability_zone" "available" {
  state = "available"
}

resource "aws_subnet" "primary" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

#============================================

# aws_iam_policy_document
# Generates an IAM policy document in JSON format for use with resources that expect policy documents such as aws_iam_policy
data "aws_iam_policy_document" "example" {
  statement {
    sid = "1"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
    ]
    #  the condition block applies to the principal (user, role, or entity) making the request
    # This condition applies to the IAM user or role making the s3:ListBucket request. Specifically:
    #If a user (e.g., Alice) is requesting s3:ListBucket, their username is substituted into "home/&{aws:username}/", allowing them to list only objects in "home/Alice/"
    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "",
        "home/",
        "home/&{aws:username}/",
      ]
    }
  }
}

resource "aws_iam_policy" "example" {
  name = "example_policy"
  # he path parameter in an AWS IAM policy specifies the hierarchical namespace under which the policy is created. The value / indicates that the policy is created at the root level of the IAM namespace
  # /app/ → Policies related to a specific application  ,  /dev/ → Policies for development environment
  path = "/"
  policy = data.aws_iam_policy_document.example.json
}

#============================================

# aws_iam_role
resource "aws_iam_role" "test_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

# another way
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "instance_role"
  # Path to the role
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

#============================================

# aws_cloudformation_export
# The CloudFormation Export data source allows access to stack exports specified in the Output section of the Cloudformation Template using the optional Export Property.

data "aws_cloudformation_export" "subnetid" {
  name = "mySubnetIdExportName"
}

resource "aws_instance" "web" {
  ami = "ami-abb07bcb"
  instance_type = "t2.micro"
  # Value from Cloudformation export identified by the export name
  subnet_id = data.aws_cloudformation_export.subnetid.value
}

#============================================

# template file
# The template_file data source renders a template from a template string, which is usually loaded from an external file
data "template_file"  "init" {
  # Inside init.tpl you can include the value of consul_address
  template = "${file("${path.module}/init.tpl")}"
  vars = {
    consul_address = "${aws_instance.consul.private_ip}"
  }
}

#============================================

# aws_cloudformation_stack
# Provides a CloudFormation Stack resource.
resource "aws_cloudformation_stack" "network" {
  name = "networking-stack"

  parameters = {
    VPCCidr = "10.0.0.0/16"
  }

  template_body = jsonencode({
    Parameters = {
      VPCCidr = {
        Type        = "String"
        Default     = "10.0.0.0/16"
        Description = "Enter the CIDR block for the VPC. Default is 10.0.0.0/16."
      }
    }

    Resources = {
      myVpc = {
        Type = "AWS::EC2::VPC"
        Properties = {
          CidrBlock = {
            "Ref" = "VPCCidr"
          }
          Tags = [
            {
              Key   = "Name"
              Value = "Primary_CF_VPC"
            }
          ]
        }
      }
    }
  })
}

#============================================

# helm_release
# A Release is an instance of a chart running in a Kubernetes cluster, A Chart is a Helm package. It contains all of the resource definitions necessary to run an application, tool, or service inside of a Kubernetes cluster.
# helm_release describes the desired status of a chart in a kubernetes cluster.
resource "helm_release" "example" {
  name       = "my-redis-release"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "6.0.1"

  set = [
    {
      name  = "cluster.enabled"
      value = "true"
    },
    {
      name  = "metrics.enabled"
      value = "true"
    }
  ]

  set = [
    {
      name  = "service.annotations.prometheus\\.io/port"
      value = "9127"
      type  = "string"
    }
  ]
}

# local chart
# In case a Chart is not available from a repository, a path may be used:
resource "helm_release" "example" {
  chart = "./charts/example"
  name  = "my-local-chart"
}

#============================================

# aws_caller_identity
# Use this data source to get the access to the effective Account ID, User ID, and ARN in which Terraform is authorized.
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

#============================================

# kubernetes_deployment_v1
# a kubernetes deployment created via terraform

resource "kubernetes_deployment_v1" "example" {
  metadata {
    name = "terraform-example"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }

    template {
      metadata {
        labels = {
          test = "MyExampleApp"
        }
      }

      spec {
        container {
          image = "nginx:1.21.6"
          name  = "example"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
              # cheme to use for connecting to the host
              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

# kubernetes_service_v1
# kubernetes service created from terraform
resource "kubernetes_service_v1" "example" {
  metadata {
    name = "terraform-example"
  }
  spec {
    selector = {
      app = kubernetes_pod.example.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 8080
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

#============================================

# aws_eks_addon
# Manages an EKS add-on.
resource "aws_eks_addon" "example1" {
  cluster_name = aws_eks_cluster.example.name
  addon_name = "vpc-cni"
}

resource "aws_eks_addon" "example2" {
  cluster_name                = aws_eks_cluster.example.name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.1" #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "PRESERVE"
}

#============================================

# Elasticsearch/ opensearch provider
# The provider is used to interact with the resources supported by Elasticsearch/Opensearch. The provider needs to be configured with an endpoint URL before it can be used.

# Configure the Elasticsearch provider
provider "elasticsearch" {
  url = "http://127.0.0.1:9200"
  addon_name = ""
  cluster_name = ""
}

# index template
resource "elasticsearch_index_template" "template_1" {
  name = "template_1"
  body = <<EOF
{
  "template": "te*",
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "type1": {
      "_source": {
        "enabled": false
      },
      "properties": {
        "host_name": {
          "type": "keyword"
        },
        "created_at": {
          "type": "date",
          "format": "EEE MMM dd HH:mm:ss Z YYYY"
        }
      }
    }
  }
}
EOF
}
































