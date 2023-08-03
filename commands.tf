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

# destroy the resources
terraform destroy
terraform destroy -auto-approve

# access all variables of the current state
terraform console 

terraform state list # lists everything that has been created
terraform state show # shows details of everything that has been created
terraform state show aws_instance.dev_node  # show specific resource

terraform output # shows all output variables

# how to unlock a locked terraform state
terraform force-unlock <id>
terraform force-unlock -force <id>

terraform refresh # refreshes the current state

# element(list, index)  : retrieves a single element from a list
element(["a", "b", "c"], 1)  # b
element(["a", "b", "c"], length(["a", "b", "c"])-1)  # c

# format(specs, values...)  :  produces a string by formatting a number of other values according to a specification string
format("There are %d lights", 4) # there are four lights
format("lpg%s-%s-%s-%02d", var.resourcetype, var.env, var.datastoretype, count.index + 1)

# terrafirm replace => to force Terraform to replace an object even though there are no configuration changes that would require it.
terraform apply -replace="aws_instance.example[0]"

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


