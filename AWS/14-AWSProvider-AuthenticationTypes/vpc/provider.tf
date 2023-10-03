provider "aws" {
  ############## first way: Hard Coded ###############
  region = "us-east-1"
#  this is a bad practice, the key can be easily leaked, never hardcode secrets!
  access_key = "my-access-key"
  secret_key = "my-secret-key"


  ############## second way: Environment Variables ###############
   #  run these commands in the terminal. terraform will pick up the variables from there
#  $ export AWS_ACCESS_KEY_ID="************"
#  $ export AWS_SECRET_ACCESS_KEY="******************"
#  $ export AWS_REGION="us-west-2"


  ############## third way: Shared Credentials ###############
#  we use the same values that have been set, when we installed aws_cli and configured it, our values come from same file
  shared_config_files = ["/Users/babak/.aws/conf"]
  shared_credentials_files = ["/Users/babak/.aws/creds"]
  profile = "customprofile"
}