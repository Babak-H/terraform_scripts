    provider "aws" {
      version = "~> 2.70.0"
      region = "${var.region}"

    /*
    In the provided Terraform AWS provider configuration code, assume_role is used to specify the details for assuming an AWS Identity and Access Management (IAM) role.
    This is a way to obtain temporary security credentials that allow the Terraform provider to make AWS API calls with the permissions granted to the assumed role.
    This is particularly useful for cross-account access, where you might need to manage resources in a different AWS account than the one your Terraform provider is
    configured to use by default.
    The assume_role block within the AWS provider configuration includes:

    role_arn: This specifies the Amazon Resource Name (ARN) of the IAM role to assume. The ARN uniquely identifies the role across AWS. This is a required parameter
    for assuming a role.
    */
      assume_role {
        role_arn = "${var.assume_role}"
      }
    }