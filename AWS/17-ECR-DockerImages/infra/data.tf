# these two variables will be filled when we apply them and will get the data from AWS and docker

# get the access to the effective Account ID, User ID, and ARN in which Terraform is authorized
data "aws_caller_identity" "current" {}

# this data source allows the authorization token, token expiration date, user name and password to be retrieved for an ECR repository.
data "aws_ecr_authorization_token" "token" {}