# install Terraform on MacOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew update
brew upgrade hashicorp/tap/terraform
touch ~/.bashrc
terraform -install-autocomplete


# - install both aws CLI and Terraform on your machine
    https://learn.hashicorp.com/tutorials/terraform/install-cli
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication
    https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
# - then configure the aws user on the machine
# create main.tf file
 terraform init                  # initialize terraform, downloads the needed provider api files that are mentioned in terraform file
 terraform plan                  # show what will be created
 terraform apply                 # create the resources
 terraform apply -auto-approve   # without any prompt to approve the apply
 terraform destroy               # destroy whatever elements was created before
 terraform destroy -auto-approve # without any prompt to approve the destory
    


terraform init # initializes terraform, downloads the needed provider api files
terraform validate # checks for all the syntaxt errors in the current project
terraform fmt # format the project and correct the formating
terraform plan # show what files will be created

# creates the resources
terraform apply
terraform apply -auto-approve  # without need to approve
# replace the old configuration of a resource with newer one, destorys the old instance and recreates it
terraform apply -replace aws_instance.dev_node.public_ip 
# in case you have other var file instead of terraform.tfvars
terraform apply -var-file="dev.tfvars"
# only apply new files and codes
terraform apply -refresh-only 
# this will replace the previous configuration of a resource with a newer/edited one. 
# a. destroys old instance 
# b. re-creates it again
terraform apply -replace aws_instance.dev_node
# terrafirm replace => to force Terraform to replace an object even though there are no configuration changes that would require it.
terraform apply -replace="aws_instance.example[0]"

# in case you have other terraform variables file instead of terraform.tfvars:
terraform apply -var-file="dev.tfvars"
terraform apply -refresh-only  # only applied new files and code

# destroy the resources
terraform destroy
terraform destroy -auto-approve
# shows what will be destroyed
terraform plan -destroy

# access all variables of the current state
terraform console 

terraform state list # lists everything that has been created
terraform state show # shows details of everything that has been created
terraform state show aws_instance.dev_node  # show specific resource
terraform state show aws_vpc.babak-vpc  # get detailed values for an item created by terraform
terraform state show aws_instance.dev-node.public_ip  # ip address of ec2 instance

# to connect to the eks cluster provisioned through terraform, we need to download the kubeconfig file of the remote cluster to the local machine
aws eks update-kubeconfig --name <CLUSTER-NAME> --region <CLUSTER-REGION>

terraform output # shows all output variables

# how to unlock a locked terraform state
terraform force-unlock <id>
terraform force-unlock -force <id>

terraform refresh # refreshes the current state

# Terraform scripts are written in HCL language.
## STRINGS
"foo" # literal string
"foo ${var.bar}" # template string


## OPERATORS
# Order of operations: 
!, - # (multiplication by -1)
*, /, % # (modulo)
+, - # (subtraction)
>, >=, <, <= # (comparison)
==, != # (equality)
&& # (AND)
|| # (OR)


## CONDITIONALS
condition ? true_val : false_val
# For example
var.a != "" ? var.a : "default-a"

interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]


## FUNCTIONS
# Numeric
abs()  ceil()  floor()  log()  max()  parseint() # parse as integer 
pow()
signum() # sign of number

# string
chomp() # remove newlines at end   
format() # format number
formatlist()  indent()  join()  lower()  regex()  regexall()  replace()  split()  strrev() # reverse string
substr()  title()  trim()  trimprefix()  trimsuffix()  trimspace()  upper()


## for_each
# This would create three copies of some_resource with the name set to "foo", "bar", and "baz" respectively
resource "some_resource" "example" {
  for_each = toset( ["foo", "bar", "baz"] )
  name     = each.key
}


// In Terraform, the element() function is used to retrieve a single element from a list by its index. The syntax for this function is as follows:
# element(list, index)
locals {
    my_list = ["a", "b", "c"]
    second_element = element(local.my_list, 1)
}

output "second_element" {
    value = local.second_element
}

# element(list, index)  : retrieves a single element from a list
element(["a", "b", "c"], 1)  # b
element(["a", "b", "c"], length(["a", "b", "c"])-1)  # c

# format(specs, values...)  :  produces a string by formatting a number of other values according to a specification string
format("There are %d lights", 4) # there are four lights
format("lpg%s-%s-%s-%02d", var.resourcetype, var.env, var.datastoretype, count.index + 1)



# Integerate Terraform and Ansible => https://medium.com/geekculture/the-most-simplified-integration-of-ansible-and-terraform-49f130b9fc8

# lookup =>  retrieves the value of a single element from a map, given its key. If the given key does not exist, the given default value is returned instead.
# lookup(map, key, default)
lookup({a="ay", b="bee"}, "a", "what?")  >> ay
lookup({a="ay", b="bee"}, "c", "whats?")  >> what?

# lifecycle meta argument => how a resouce reacts to different changes after it has been deployed
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
# associated remote object.
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      tags,
    ]
  }
}

# dynamic block => when we need to nest several child resources inside a parent resource, but without re-writing it several times https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
resource "aws_elastic_beanstalk_environment" "tfenvtest" {
  name                = "tf-test-name"
  # this is the dynamic block, write dynamic before the resource name
  dynamic "setting" {
    for_each = var.settings
    content {
      name = setting.value["name"]
      value = setting.value["value"]
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
}

# **** Terraform tips *****
# - Terraform only works when you merge branches into main branch (gets triggered)
# - Always follow naming convention when creating resources in terraform
# - CICD pipeline : terraform -> ansible call for dynamic inventory


 # *** Upgrade Terraform Module's Version ***

### Core-Operator migration from 0.11.15 to 1.4.6 ###

1. Run the pipeline at version 0.11.15, this step should be without issues except the error related to re-creating the Service Account, for Branch DYN-*****-0.11
2. set the terraform version to 0.12.12 , this is required for first time due to errors if we set the version to higher than 0.12 sub versions, which is caused by how the formatting of the state files changes in higher terraform versions. only other solution I have found online was to delete and recreate the state file. comment the 
   aws_iam_role_policy.my_access_policy , this will allow the the OIDC role to be deleted. this will throw an error that Role already exists (plus SA error).  Branch DYN-****-add-harness-0.12
3. set the version to 0.12.31 , and uncomment aws_iam_role_policy.my_access_policy and run the pipeline. will throw an error that there is wrong value for the policy "MalformedPolicyDocumentException" , re-run the pipeline and the issue will be fixed (will still get the SA error)  Branch DYN-****-add-harness-0.12
4. run the version 0.13.7 pipeline, no changes should be visible here (except SA error)  Branch DYN-****-add-harness-0.12
5. run the pipeline version 1.0.7 . here we should see changes related to object_naming.random_string.GUID_GENERATED, aws_s3_bucket_versioning.versioning, aws_s3_bucket_server_side_encryption_configuration.encryption, aws_s3_bucket_public_access_block.deny_public_access, aws_s3_bucket_logging.logging, aws_s3_bucket_lifecycle_configuration.lifecycle, bucket.aws_s3_bucket_acl.acl[0]  being created, this is due to fact that we are moving from older version of s3-bucket to a newer and remote version CP has created, the Role for OIDC will also be recreated as we are moving from internal oidc module to the one hosted on core  Branch DYN-****-add-harness-1.0.7
6. at this point terraform state is at version 1.0.7 and we can delete the Service account manually from command line and recreate it from pipeline. in lower terraform versions it wouldn't be useful since due to terraform bugs deleting and recreating SA would just cause the error to be reestablished the next time we run the pipeline. run the pipeline again on version of 1.0.7 of terraform, it will re-create the Service account and update some resources that are directly related to it. to make sure everything is working fine, re-run the plan again, there should not be ANY resource that needs creation or update.  Branch DYN-****-add-harness-1.0.7
7. run the pipeline with terraform version 1.4.6  , it should not re-create any resource, but will update the state to terraform 1.4.6  Branch DYN-***-add-updates

# What does terraform apply/plan refresh-only do?
# A "normal" terraform plan includes two main behaviors: Update the state from the previous run to reflect any changes made outside of Terraform. That's called "refreshing" in Terraform terminology.
# Comparing that updated state with the desired state described by the configuration, and in case of any differences generating a proposed set of actions to change the real remote objects to match the desired state.
# When you create a "refresh-only" plan, you're disabling the second of those, but still performing the first. Terraform will update the state to match changes made outside of Terraform, and then ask you if you want to commit that result as a new state snapshot to use on future runs. Typically the desired result of a refresh-only plan is for Terraform to report that there were no changes outside of Terraform, although Terraform does allow you to commit the result as a new state snapshot if you wish, for example if the changes cascaded from an updated object used as a data resource and you want to save those new results.


