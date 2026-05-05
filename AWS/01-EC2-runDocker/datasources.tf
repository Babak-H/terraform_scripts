# This avoids hard-coding AMI name patterns and automatically tracks the latest Ubuntu 24.04 LTS server image in the selected AWS region
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}
