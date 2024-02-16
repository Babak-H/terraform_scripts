# here we need to access the eks cluster that was created in another project and saved in it's state
# remote state can be on aws S3 bucket / terraformCloud or on the local machine
/*
data "terraform_remote_state" "eks" {
    backend = "local"
    config = {
      path = "../eks-infra/terraform.tfstate"
    }
}
*/

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-on-aws-eks"
    key = "dev/eks-cluster/terraform.tfstate"
    region = var.aws_region
  }
}

# Datasource: EBS CSI IAM Policy get from EBS GIT Repo (latest)
# this will download the json file as Terraform data
data "http" "ebs_csi_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json"
  
  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

output "ebs_csi_iam_policy" {
  value = data.http.ebs_csi_iam_policy.response_body
}

/*
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ]
*/