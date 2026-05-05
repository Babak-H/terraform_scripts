# Terraform CLI notes and HCL snippets
#
# This file is a cheat sheet. Commands and examples are commented so the file can
# live in a Terraform repo without being interpreted as real infrastructure


# Install Terraform on macOS with Homebrew:
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
#
# Upgrade Terraform on macOS:
brew update
brew upgrade hashicorp/tap/terraform
#
# Enable shell autocomplete:
touch ~/.bashrc
terraform -install-autocomplete
#
# References:
#   https://developer.hashicorp.com/terraform/install
#   https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication
#   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
#
# After installing the AWS CLI, configure credentials:
aws configure


# Common Terraform workflow:
terraform init                  # Initialize the working directory and install providers/modules
terraform fmt                   # Format Terraform configuration files
terraform fmt -recursive
terraform validate              # Check syntax and internal consistency
terraform plan                  # Preview proposed infrastructure changes
terraform apply                 # Apply proposed changes after confirmation
terraform apply -auto-approve   # Apply without interactive approval
terraform destroy               # Destroy managed resources after confirmation
terraform destroy -auto-approve # Destroy without interactive approval


# Useful variants:
terraform init -backend-config=../../backends/eu-west-2/LOCAL.tfvars
terraform init -upgrade
terraform plan -var-file="./D-1/terraform.tfvars"
terraform plan -destroy
terraform apply -var-file="dev.tfvars"
#
# If you use a shorter shell alias, point it at your current Terraform binary:
alias tf="terraform"

# Avoid pinning aliases to very old binaries such as Terraform 0.12.31 unless you are intentionally maintaining legacy state/configuration.


# Replace resources:
# Force Terraform to destroy and recreate a resource even when the configuration change does not otherwise require replacement
terraform apply -replace="aws_instance.dev_node"
terraform apply -replace="aws_instance.example[0]"

# Use a resource address, not an attribute address. For example, this is invalid:
terraform apply -replace="aws_instance.dev_node.public_ip"


# Refresh-only mode:
# Terraform plan/apply already refresh state in memory before comparing desired
# configuration with remote objects. Use refresh-only mode when you want to
# update the state file to "match remote drift" without changing remote resources
terraform plan -refresh-only
terraform apply -refresh-only

# The legacy command below is deprecated because it updates state immediately without the safer review step:
terraform refresh


# State inspection and maintenance:
terraform output
terraform console
terraform state list
terraform state show aws_instance.dev_node
terraform state show aws_vpc.babak_vpc

# Unlock a locked state only after confirming no Terraform run is still active:
terraform force-unlock <LOCK_ID>
terraform force-unlock -force <LOCK_ID>

# Move an existing object to a new Terraform address:
terraform state mv 'module.my_module.some_resource.resource_name' 'module.other_module.some_resource.resource_name'


# EKS kubeconfig, To connect kubectl to an EKS cluster provisioned through Terraform:
aws eks update-kubeconfig --name <CLUSTER_NAME> --region <CLUSTER_REGION>


# Terraform scripts are written in HCL.

# Strings:
"foo"             # Literal string.
"foo ${var.bar}"  # Template string.


# Operators, from highest to lowest precedence:
!, -
*, /, %
+, -
>, >=, <, <=
==, !=
&&
||


# Conditionals:
condition ? true_val : false_val
var.a != "" ? var.a : "default-a"
var.host_os == "windows" ? ["PowerShell", "-Command"] : ["bash", "-c"]


# Common functions:

# Numeric:
abs()
ceil()
floor()
log()
max()
parseint()  # parse as integer 
pow()
signum() # sign of number

# String:
chomp()   # remove newlines at end  
format()
formatlist()
indent()
join()
lower()
regex()
regexall()
replace()
split()
strrev()
substr()
title()
trim()
trimprefix()
trimsuffix()
trimspace()
upper()


# for_each example:
# This would create three copies of some_resource with the name set to "foo", "bar", and "baz" respectively
resource "some_resource" "example" {
  for_each = toset(["foo", "bar", "baz"])
  name     = each.key
}


# element(list, index):
# The element function retrieves a single element from a list by index. It wraps around for indexes greater than the list length, but direct index syntax is
# usually clearer when you do not need wrap-around behavior.
element(["a", "b", "c"], 1)                         # "b"
element(["a", "b", "c"], length(["a", "b", "c"]) - 1) # "c"
["a", "b", "c"][1]                                  # "b"

locals {
    my_list = ["a", "b", "c"]
    second_element = element(local.my_list, 1)
}

output "second_element" {
    value = local.second_element
}


# format(specs, values...)  :  produces a string by formatting a number of other values according to a specification string
format("There are %d lights", 4)
format("lpg%s-%s-%s-%02d", var.resource_type, var.env, var.datastore_type, count.index + 1)

# Integerate Terraform and Ansible => https://medium.com/geekculture/the-most-simplified-integration-of-ansible-and-terraform-49f130b9fc8


# lookup(map, key, default):
# lookup =>  retrieves the value of a single element from a map, given its key. If the given key does not exist, the given default value is returned instead
lookup({ a = "ay", b = "bee" }, "a", "what?")  # "ay"
lookup({ a = "ay", b = "bee" }, "c", "what?")  # "what?"


# lifecycle meta-argument:
# Controls how a resource reacts to changes after it has been deployed.
# Create a replacement before destroying the old object:
resource "azurerm_resource_group" "example" {
  # ...
  # normally terraform destroys a resource before creating a new one, here we tell it to first create new one and then destroy previous version
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "example" {
  # ...
  lifecycle {
    # The ignore_changes feature is intended to be used when a resource is created with references to data that may change in the future, but should not affect said resource after its creation. 
    # In some rare cases, settings of a remote object are modified by processes outside of Terraform, which Terraform would then attempt to "fix" on the next run. In order to make Terraform share 
    # management responsibilities of a single object with a separate process, the ignore_changes meta-argument specifies resource attributes that Terraform should ignore when planning updates to the 
    # associated remote object
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      tags,
    ]
  }
}

# dynamic block => when we need to nest several child resources inside a parent resource, but without re-writing it several times
resource "aws_elastic_beanstalk_environment" "tfenvtest" {
  name                = "tf-test-name"

  # this is the dynamic block, write "dynamic" before the resource name (here "setting")
  dynamic "setting" {
    for_each = var.settings
    content {
      namespace = setting.value.value
      name      = setting.value.name
      value     = setting.value.value
    }
  }
}

# Provider Metadata => Provider Metadata allows a provider to declare metadata fields it expects, which individual modules can then populate independently of any provider configuration. While provider configurations are often shared between modules, provider metadata is always module-specific.
# to include data in your modules, create a provider_meta nested block under your module's terraform block, with the name of the provider it's trying to pass information to:
terraform {
  provider_meta "my-provider" {
    hello = "world"
  }
}

# How to set default values for a object in terraform?
# Object variable with defaults:
variable "machine_details" {
  type = object({
    name = string
    size = string
    username = string
    password = string
  })

  default = {
      name = "example-vm"
      size = "Standard_F2"
      username  = "adminuser"
      password = "Notallowed1!"
    }
    sensitive = true
}


# Prefer passing real passwords through a secret manager, environment-specific tfvars excluded from Git, or CI/CD secret variables rather than hard-coding
# them in configuration.


# Terraform tips:
# - Commit .terraform.lock.hcl for provider version reproducibility
# - Keep provider blocks in the root module when possible
# - Use modules for repeated infrastructure patterns
# - Use consistent naming conventions for resources and tags
# - CI/CD often runs: terraform fmt -check, terraform init, terraform validate, terraform plan, then terraform apply after approval.


# Terraform and Ansible:
# Terraform is best used to provision infrastructure
# Ansible is best used to configure hosts after they exist
# Common integration pattern: Terraform outputs inventory data, then CI/CD passes that inventory to Ansible


### Core-Operator migration from 0.11.15 to 1.4.6 ###

# 1. Run the pipeline at version 0.11.15, this step should be without issues except the error related to re-creating the Service Account, for Branch DYN-*****-0.11
# 2. set the terraform version to 0.12.12, this is required for first time due to errors if we set the version to higher than 0.12 sub versions, which is caused by how the formatting of the state files changes in higher terraform versions. only other solution I have found online was to delete and recreate the state file. comment the 
#    aws_iam_role_policy.my_access_policy, this will allow the the OIDC role to be deleted. this will throw an error that Role already exists (plus SA error).  Branch DYN-****-add-harness-0.12
# 3. set the version to 0.12.31 , and uncomment aws_iam_role_policy.my_access_policy and run the pipeline. will throw an error that there is wrong value for the policy "MalformedPolicyDocumentException" , re-run the pipeline and the issue will be fixed (will still get the SA error)  Branch DYN-****-add-harness-0.12
# 4. run the version 0.13.7 pipeline, no changes should be visible here (except SA error)  Branch DYN-****-add-harness-0.12
# 5. run the pipeline version 1.0.7, here we should see changes related to object_naming.random_string.GUID_GENERATED, aws_s3_bucket_versioning.versioning, aws_s3_bucket_server_side_encryption_configuration.encryption, aws_s3_bucket_public_access_block.deny_public_access, aws_s3_bucket_logging.logging, aws_s3_bucket_lifecycle_configuration.lifecycle, bucket.aws_s3_bucket_acl.acl[0]  being created, this is due to fact that we are moving from older version of s3-bucket to a newer and remote version CP has created, the Role for OIDC will also be recreated as we are moving from internal oidc module to the one hosted on core  Branch DYN-****-add-harness-1.0.7
# 6. at this point terraform state is at version 1.0.7 and we can delete the Service account manually from command line and recreate it from pipeline. in lower terraform versions it wouldn't be useful since due to terraform bugs deleting and recreating SA would just cause the error to be reestablished the next time we run the pipeline. run the pipeline again on version of 1.0.7 of terraform, it will re-create the Service account and update some resources that are directly related to it. to make sure everything is working fine, re-run the plan again, there should not be ANY resource that needs creation or update.  Branch DYN-****-add-harness-1.0.7
# 7. run the pipeline with terraform version 1.4.6  , it should not re-create any resource, but will update the state to terraform 1.4.6  Branch DYN-***-add-updates

# What does terraform apply/plan refresh-only do?
# terraform apply -refresh-only
# A "normal" terraform plan includes two main behaviors: Update the state from the previous run to reflect any changes made outside of Terraform. That's called "refreshing" in Terraform terminology.
# Comparing that updated state with the desired state described by the configuration, and in case of any differences generating a proposed set of actions to change the real remote objects to match the desired state.
# When you create a "refresh-only" plan, you're disabling the second of those, but still performing the first. Terraform will update the state to match changes made outside of Terraform, and then ask you if you want to commit that result as a new state snapshot to use on future runs. Typically the desired result of a refresh-only plan is for Terraform to report that there were no changes outside of Terraform, although Terraform does allow you to commit the result as a new state snapshot if you wish, for example if the changes cascaded from an updated object used as a data resource and you want to save those new results.

# if a local variable and global variable both have the same name, terraform will only read the global one and ignore the local variable inside the resources.



# Provider configuration not present:

# Error pattern:
# To work with "module.my_module.some_resource.resource_name" its original provider configuration at "module.my_module.provider.some_provider.provider_name" is required, but it
# has been removed. 

# Cause:
# This occurs when a provider configuration is removed while objects created by that provider still exist in the state

# Fix options:
# - Re-add the missing provider configuration, destroy the old resources, then remove the provider configuration
# - If the resource moved, use terraform state mv to update its address
# - If the provider source changed, use terraform state replace-provider


# Terraform has detected that there are resource objects still present in the state whose provider configurations are not available, and so it doesn't have enough information to destroy those resources.
# there is a provider configuration block in one of your child modules. While that is permitted for compatibility with older versions of Terraform, it's recommended to only have provider blocks in your root module so that they can always outlive any resource instances that the provider is managing
# If your intent is to destroy the resource instances in module.my_module then you must do that before removing the module "my_module" block from the root module. This is one unusual situation where we can use -target to help Terraform understand what we want it to do:
terraform destroy -target=module.my_module

# Do not use -target as a routine workflow. It is for exceptional recovery or migration cases because it can skip related changes Terraform would normally
# include in the full graph.


# If your goal is to move resource blocks into another module, the other possible resolution here is to use terraform state mv to instruct Terraform to track the existing object under a new address:
terraform state mv 'module.my_module.some_resource.resource_name' 'module.other_module.some_resource.resource_name'



# if you have terraform connected to an AWS account and want to create one resource with specific name and tags, but when applying it gets rejected because "resource with exact same name" exists, what can you do to fix it?

# This is a classic Terraform state/drift problem. The resource exists in AWS but Terraform doesn't know about it. You have a few options depending on your situation:

## Option 1: Import the existing resource (best approach)
# Tell Terraform to adopt the already-existing resource into its state instead of trying to create a new one:

terraform import aws_s3_bucket.my_bucket my-existing-bucket-id

# terraform import <resource_type>.<resource_name> <aws_resource_id> , After importing, run `terraform plan` — if your config matches the real resource, there will be no diff and you're done.


## Option 2: Use `import` block (Terraform 1.5+, cleaner)
# You can declare the import directly in your .tf file:

import {
  to = aws_s3_bucket.my_bucket
  id = "my-existing-bucket-id"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-existing-bucket-id"
  tags = {
    Env = "prod"
  }
}

# Then run terraform plan and terraform apply. This is more auditable since the import intent lives in code.


## Option 3: Rename your resource in Terraform
# If the existing AWS resource is unrelated/unneeded and you just want to avoid the collision, change the `name` in your Terraform config to something unique:

resource "aws_iam_role" "my_role" {
  name = "my-role-v2"  # changed from "my-role"
  ...
}


## Which to choose?

# | Situation                                                                               | Best Option |
# | Resource was created outside Terraform (manually or by another tool)                    | **Import** |
# | Resource was previously managed by Terraform but state was lost                         | **Import** |
# | The existing resource is unrelated/old/unused                                           | **Delete it**, then apply |
# | You just need a different name                                                          | **Rename in config** |

# The **import** path is almost always the right call — it avoids downtime and lets Terraform take over management cleanly. After importing, always run `terraform plan` to confirm there's no unintended drift between your config and the real resource state.

# this is how we can see who is the current person that is using this AWS account:
data "aws_caller_identity" "current" {}

# how to use it
data.aws_caller_identity.current.account_id