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
terraform apply -refresh-only # only apply new files and codes

# destroy the resources
terraform destroy
terraform destroy -auto-approve

terraform console # access all variables of the current state

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