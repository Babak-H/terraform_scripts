# Terraform Commands and Notes

This is a Terraform CLI and HCL cheat sheet. It includes common commands, useful variants, state operations, HCL examples, troubleshooting patterns, and migration notes.

## Install and Configure

### Install Terraform on macOS

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Upgrade Terraform on macOS

```bash
brew update
brew upgrade hashicorp/tap/terraform
```

### Enable shell autocomplete

```bash
touch ~/.bashrc
terraform -install-autocomplete
```

### Configure AWS credentials

After installing the AWS CLI:

```bash
aws configure
```

### References

- Terraform install: <https://developer.hashicorp.com/terraform/install>
- AWS provider authentication: <https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication>
- AWS CLI install: <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

## Common Terraform Workflow

| Command | Purpose |
|---|---|
| `terraform init` | Initialize the working directory and install providers/modules. |
| `terraform fmt` | Format Terraform configuration files. |
| `terraform fmt -recursive` | Format Terraform files recursively. |
| `terraform validate` | Check syntax and internal consistency. |
| `terraform plan` | Preview proposed infrastructure changes. |
| `terraform apply` | Apply proposed changes after confirmation. |
| `terraform apply -auto-approve` | Apply without interactive approval. |
| `terraform destroy` | Destroy managed resources after confirmation. |
| `terraform destroy -auto-approve` | Destroy without interactive approval. |

```bash
terraform init
terraform fmt
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform destroy
```

## Useful Command Variants

```bash
terraform init -backend-config=../../backends/eu-west-2/LOCAL.tfvars
terraform init -upgrade
terraform plan -var-file="./D-1/terraform.tfvars"
terraform plan -destroy
terraform apply -var-file="dev.tfvars"
```

If you use a shorter shell alias, point it at your current Terraform binary:

```bash
alias tf="terraform"
```

Avoid pinning aliases to very old binaries such as Terraform `0.12.31` unless you are intentionally maintaining legacy state or legacy configuration.

## Replace Resources

Use `-replace` to force Terraform to destroy and recreate a resource even when the configuration change does not otherwise require replacement.

```bash
terraform apply -replace="aws_instance.dev_node"
terraform apply -replace="aws_instance.example[0]"
```

Use a resource address, not an attribute address.

Invalid example:

```bash
terraform apply -replace="aws_instance.dev_node.public_ip"
```

## Refresh-Only Mode

Terraform `plan` and `apply` already refresh state in memory before comparing desired configuration with remote objects.

Use refresh-only mode when you want to update the state file to match remote drift without changing remote resources.

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

The legacy command below is deprecated because it updates state immediately without the safer review step:

```bash
terraform refresh
```

## State Inspection and Maintenance

```bash
terraform output
terraform console
terraform state list
terraform state show aws_instance.dev_node
terraform state show aws_vpc.babak_vpc
```

Unlock a locked state only after confirming no Terraform run is still active:

```bash
terraform force-unlock <LOCK_ID>
terraform force-unlock -force <LOCK_ID>
```

Move an existing object to a new Terraform address:

```bash
terraform state mv 'module.my_module.some_resource.resource_name' 'module.other_module.some_resource.resource_name'
```

## EKS Kubeconfig

Connect `kubectl` to an EKS cluster provisioned through Terraform:

```bash
aws eks update-kubeconfig --name <CLUSTER_NAME> --region <CLUSTER_REGION>
```

## HCL Basics

Terraform configuration is written in HCL.

### Strings

```hcl
"foo"             # Literal string
"foo ${var.bar}"  # Template string
```

### Operators

Operators from highest to lowest precedence:

```text
!, -
*, /, %
+, -
>, >=, <, <=
==, !=
&&
||
```

### Conditionals

```hcl
condition ? true_val : false_val
var.a != "" ? var.a : "default-a"
var.host_os == "windows" ? ["PowerShell", "-Command"] : ["bash", "-c"]
```

## Common Functions

### Numeric functions

```hcl
abs()
ceil()
floor()
log()
max()
parseint() # Parse as integer
pow()
signum()  # Sign of number
```

### String functions

```hcl
chomp() # Remove newlines at end
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
```

## `for_each` Example

This creates three copies of `some_resource` with the name set to `foo`, `bar`, and `baz`.

```hcl
resource "some_resource" "example" {
  for_each = toset(["foo", "bar", "baz"])
  name     = each.key
}
```

## `element(list, index)`

The `element` function retrieves a single element from a list by index. It wraps around for indexes greater than the list length, but direct index syntax is usually clearer when wrap-around behavior is not needed.

```hcl
element(["a", "b", "c"], 1)                           # "b"
element(["a", "b", "c"], length(["a", "b", "c"]) - 1) # "c"
["a", "b", "c"][1]                                    # "b"
```

```hcl
locals {
  my_list        = ["a", "b", "c"]
  second_element = element(local.my_list, 1)
}

output "second_element" {
  value = local.second_element
}
```

## `format(specs, values...)`

The `format` function produces a string by formatting values according to a specification string.

```hcl
format("There are %d lights", 4)
format("lpg%s-%s-%s-%02d", var.resource_type, var.env, var.datastore_type, count.index + 1)
```

## Terraform and Ansible

Terraform is best used to provision infrastructure.

Ansible is best used to configure hosts after they exist.

Common integration pattern:

```text
Terraform creates infrastructure
-> Terraform outputs inventory data
-> CI/CD passes inventory to Ansible
-> Ansible configures the hosts
```

Reference:

<https://medium.com/geekculture/the-most-simplified-integration-of-ansible-and-terraform-49f130b9fc8>

## `lookup(map, key, default)`

`lookup` retrieves the value of a single element from a map. If the key does not exist, the default value is returned.

```hcl
lookup({ a = "ay", b = "bee" }, "a", "what?") # "ay"
lookup({ a = "ay", b = "bee" }, "c", "what?") # "what?"
```

## Lifecycle Meta-Argument

The `lifecycle` meta-argument controls how a resource reacts to changes after it has been deployed.

### `create_before_destroy`

Create a replacement before destroying the old object.

```hcl
resource "azurerm_resource_group" "example" {
  # ...

  lifecycle {
    create_before_destroy = true
  }
}
```

### `ignore_changes`

Use `ignore_changes` when a resource is created with references to data that may change later but should not affect the resource after creation.

It is also useful when something outside Terraform modifies a remote object and Terraform should not try to "fix" it on the next run.

```hcl
resource "aws_instance" "example" {
  # ...

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
```

## Dynamic Blocks

Use a `dynamic` block when you need to nest several child blocks inside a parent resource without rewriting the same block several times.

```hcl
resource "aws_elastic_beanstalk_environment" "tfenvtest" {
  name = "tf-test-name"

  dynamic "setting" {
    for_each = var.settings

    content {
      namespace = setting.value.value
      name      = setting.value.name
      value     = setting.value.value
    }
  }
}
```

## Provider Metadata

Provider metadata lets a provider declare metadata fields it expects. Individual modules can then populate those fields independently of provider configuration.

Provider configurations are often shared between modules, but provider metadata is module-specific.

```hcl
terraform {
  provider_meta "my-provider" {
    hello = "world"
  }
}
```

## Object Variable With Defaults

Example object variable:

```hcl
variable "machine_details" {
  type = object({
    name     = string
    size     = string
    username = string
    password = string
  })

  default = {
    name     = "example-vm"
    size     = "Standard_F2"
    username = "adminuser"
    password = "CHANGE_ME"
  }

  sensitive = true
}
```

Prefer passing real passwords through a secret manager, environment-specific `.tfvars` files excluded from Git, or CI/CD secret variables instead of hard-coding them in configuration.

## Terraform Tips

- Commit `.terraform.lock.hcl` for provider version reproducibility.
- Keep provider blocks in the root module when possible.
- Use modules for repeated infrastructure patterns.
- Use consistent naming conventions for resources and tags.
- CI/CD often runs `terraform fmt -check`, `terraform init`, `terraform validate`, `terraform plan`, and then `terraform apply` after approval.

## Core-Operator Migration: Terraform 0.11.15 to 1.4.6

This is a historical migration workflow from Terraform `0.11.15` to `1.4.6`.

1. Run the pipeline at Terraform `0.11.15`.

   Expected issue: error related to recreating the Service Account.

   Branch: `DYN-*****-0.11`

2. Set Terraform version to `0.12.12`.

   This version is required first because higher `0.12.x` versions can error due to state file formatting changes. Another possible solution is deleting and recreating the state file, but that is more disruptive.

   Temporarily comment:

   ```hcl
   aws_iam_role_policy.my_access_policy
   ```

   This allows the OIDC role to be deleted. It may throw `Role already exists` plus the Service Account error.

   Branch: `DYN-****-add-harness-0.12`

3. Set Terraform version to `0.12.31`.

   Uncomment:

   ```hcl
   aws_iam_role_policy.my_access_policy
   ```

   Run the pipeline. It may throw a `MalformedPolicyDocumentException`. Re-run the pipeline and the issue should be fixed, though the Service Account error may remain.

   Branch: `DYN-****-add-harness-0.12`

4. Run the Terraform `0.13.7` pipeline.

   No changes should be visible except the Service Account error.

   Branch: `DYN-****-add-harness-0.12`

5. Run the Terraform `1.0.7` pipeline.

   Expected changes may include:

   - `object_naming.random_string.GUID_GENERATED`
   - `aws_s3_bucket_versioning.versioning`
   - `aws_s3_bucket_server_side_encryption_configuration.encryption`
   - `aws_s3_bucket_public_access_block.deny_public_access`
   - `aws_s3_bucket_logging.logging`
   - `aws_s3_bucket_lifecycle_configuration.lifecycle`
   - `bucket.aws_s3_bucket_acl.acl[0]`

   This happens because the S3 bucket module is moving from an older version to a newer remote version. The OIDC role may also be recreated when moving from an internal OIDC module to the one hosted on core.

   Branch: `DYN-****-add-harness-1.0.7`

6. After state is at Terraform `1.0.7`, manually delete the Service Account from the command line and recreate it from the pipeline.

   Lower Terraform versions may recreate the error on the next run due to Terraform bugs.

   Re-run the Terraform `1.0.7` pipeline. It should recreate the Service Account and update directly related resources. Re-run `plan` afterward to confirm no resource needs creation or update.

   Branch: `DYN-****-add-harness-1.0.7`

7. Run the pipeline with Terraform `1.4.6`.

   It should not recreate resources, but it should update state to Terraform `1.4.6`.

   Branch: `DYN-***-add-updates`

## Refresh-Only Explanation

A normal Terraform plan has two main behaviors:

1. Refresh state from the previous run to reflect remote changes.
2. Compare refreshed state with desired configuration and produce proposed actions.

When you create a refresh-only plan, you disable the second behavior while keeping the first.

Terraform updates state to match remote changes and then asks whether you want to commit that result as a new state snapshot.

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

Typical desired result:

```text
No changes outside of Terraform.
```

Terraform can still let you commit a refreshed snapshot if remote changes cascaded from data sources or other external updates.

## Variable Name Precedence Note

If a local variable and a global variable both have the same name, Terraform will read the global one and ignore the local variable inside the resources.

## Provider Configuration Not Present

### Error pattern

```text
To work with "module.my_module.some_resource.resource_name" its original provider configuration at
"module.my_module.provider.some_provider.provider_name" is required, but it has been removed.
```

### Cause

This occurs when a provider configuration is removed while objects created by that provider still exist in the state.

### Fix options

- Re-add the missing provider configuration, destroy the old resources, then remove the provider configuration.
- If the resource moved, use `terraform state mv` to update its address.
- If the provider source changed, use `terraform state replace-provider`.

Terraform has detected resource objects still present in state whose provider configurations are not available, so it does not have enough information to destroy those resources.

This can happen when a provider configuration block is in a child module. While that is permitted for compatibility with older Terraform versions, it is recommended to keep provider blocks in the root module so they can outlive resource instances managed by the provider.

If the goal is to destroy resource instances in `module.my_module`, destroy them before removing the module block from the root module.

In this unusual case, `-target` can help Terraform understand the desired recovery action:

```bash
terraform destroy -target=module.my_module
```

Do not use `-target` as a routine workflow. It is for exceptional recovery or migration cases because it can skip related changes Terraform would normally include in the full graph.

If the goal is to move resource blocks into another module, use `terraform state mv`:

```bash
terraform state mv 'module.my_module.some_resource.resource_name' 'module.other_module.some_resource.resource_name'
```

## Resource Already Exists in AWS

Problem:

You have Terraform connected to an AWS account and want to create a resource with a specific name and tags, but `terraform apply` fails because a resource with the exact same name already exists.

This is a Terraform state or drift problem. The resource exists in AWS, but Terraform does not know about it.

### Option 1: Import the existing resource

Best approach when the resource should be managed by Terraform.

```bash
terraform import aws_s3_bucket.my_bucket my-existing-bucket-id
```

Pattern:

```bash
terraform import <resource_type>.<resource_name> <aws_resource_id>
```

After importing, run:

```bash
terraform plan
```

If your config matches the real resource, there should be no diff.

### Option 2: Use an import block

Terraform `1.5+` supports import blocks.

```hcl
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
```

Then run:

```bash
terraform plan
terraform apply
```

This is more auditable because the import intent lives in code.

### Option 3: Rename the resource in Terraform

If the existing AWS resource is unrelated or unneeded, and you only need to avoid the name collision, change the name in Terraform configuration.

```hcl
resource "aws_iam_role" "my_role" {
  name = "my-role-v2"

  # ...
}
```

### Choosing the right option

| Situation | Best option |
|---|---|
| Resource was created outside Terraform manually or by another tool. | Import it. |
| Resource was previously managed by Terraform but state was lost. | Import it. |
| Existing resource is unrelated, old, or unused. | Delete it, then apply. |
| You just need a different name. | Rename it in config. |

The import path is almost always the right call. It avoids downtime and lets Terraform take over management cleanly.

After importing, always run `terraform plan` to confirm there is no unintended drift between your config and the real resource state.

## Current AWS Account Identity

Use `aws_caller_identity` to identify the current AWS account.

```hcl
data "aws_caller_identity" "current" {}
```

Use it like this:

```hcl
data.aws_caller_identity.current.account_id
```

---

## Update an Existing AWS IAM Policy

Question: How do you update an AWS IAM policy with Terraform if the policy already exists?

Terraform manages the full JSON document in the `policy` argument of `aws_iam_policy`. When you change that JSON document, Terraform updates the managed policy by creating a new IAM policy version and setting it as the default version.

If the policy already exists in AWS but is not in Terraform state, import it first. The import workflow is covered earlier in this file, so this section only shows the command shape:

```bash
terraform import aws_iam_policy.ec2_create_start_open arn:aws:iam::123456789012:policy/AllowCreateStartEC2
```

### Initial Open Policy

Example policy that allows creating and starting EC2 instances:

```hcl
data "aws_iam_policy_document" "ec2_create_start_open" {
  statement {
    sid    = "AllowCreateAndStartEC2"
    effect = "Allow"

    actions = [
      "ec2:RunInstances",
      "ec2:StartInstances",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_create_start_open" {
  name   = "AllowCreateStartEC2"
  policy = data.aws_iam_policy_document.ec2_create_start_open.json
}
```

### Restrict the Policy by Source IP

Example: allow requests only from `203.0.113.10/32`.

```hcl
data "aws_iam_policy_document" "ec2_create_start_restricted_ip" {
  statement {
    sid    = "AllowCreateAndStartEC2FromSpecificIP"
    effect = "Allow"

    actions = [
      "ec2:RunInstances",
      "ec2:StartInstances",
    ]

    resources = ["*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["203.0.113.10/32"]
    }
  }
}

resource "aws_iam_policy" "ec2_create_start_open" {
  name        = "AllowCreateStartEC2"
  description = "Allows creating and starting EC2 instances only from a specific IP"
  policy      = data.aws_iam_policy_document.ec2_create_start_restricted_ip.json
}
```

Then run:

```bash
terraform plan
terraform apply
```

Notes:

- `aws:SourceIp` works for public AWS API calls.
- If requests come through a VPC endpoint, use a condition such as `aws:SourceVpce`.
- Older non-default IAM policy versions may remain in AWS, but only the default policy version is active.

## Manual Resources vs Prebuilt Modules

Question: Is there any benefit to manually writing all Terraform resources instead of using prebuilt modules from the Terraform Registry?

Yes. Both approaches can be valid.

### Prebuilt modules

Best when you want:

- Faster delivery.
- Standard patterns.
- Less boilerplate.
- Community-tested or organization-approved defaults.

Risks:

- Hidden complexity.
- Opinionated design that may not match your environment.
- Upgrade drift or breaking changes.
- Less direct control over resource-level details.

### Manual resources

Best when you need:

- Full control over every setting.
- A deeper understanding of what is deployed.
- Fine-grained security or compliance customization.
- Easier debugging at the resource level.

Costs:

- More time and maintenance.
- More chance of inconsistency across projects.
- More repeated code unless you later wrap it in modules.

### Practical recommendation

Use a hybrid model:

- Start with trusted modules for common building blocks such as VPCs, EKS, databases, and IAM patterns.
- Pin module versions.
- Wrap external modules in your own internal modules when standardization matters.
- Write resources manually where requirements are unique, sensitive, or compliance-heavy.

Manual resources are not automatically better, but they are valuable for learning, strict control, and unusual requirements.

## Unmanaged AWS Resources

Question: What happens if Terraform creates some resources, and later someone creates unrelated VPCs, S3 buckets, or other resources manually in the same AWS account?

Terraform generally ignores resources that are not in its configuration and not in its state.

On the next `terraform apply`:

- Terraform compares configuration against state for managed objects only.
- Unrelated AWS resources created outside Terraform are not changed or deleted.
- Terraform still creates, updates, or destroys only what your code declares.

Possible exceptions:

- Name collisions can cause create failures, especially for globally unique names such as S3 buckets.
- Data sources that query the account may return different results if unmanaged resources match their filters.
- If a Terraform-managed resource was changed or deleted manually, Terraform can detect drift and try to reconcile it.

Short version: unrelated resources are normally ignored, but naming, data sources, and drift can still affect plans.

## Types of Terraform Modules

Terraform modules are reusable containers for Terraform configuration files. They help organize infrastructure code and avoid repetition.

### Root module

The root module is the main Terraform configuration in the directory where Terraform is run.

It usually:

- Defines the main infrastructure entry point.
- Calls child modules.
- Provides input variables, backend configuration, and provider configuration.

```hcl
module "network" {
  source = "./modules/network"

  vpc_cidr = "10.0.0.0/16"
}
```

### Child module

A child module is a module called by another module, usually from the root module.

It is used to:

- Reuse infrastructure logic.
- Organize code by component, such as networking, compute, or database.
- Reduce duplication.

Example folder structure:

```text
terraform-project/
+-- main.tf
+-- variables.tf
+-- outputs.tf
+-- modules/
    +-- network/
        +-- main.tf
        +-- variables.tf
        +-- outputs.tf
```

### Local module

A local module is stored in the same repository or filesystem as the root module.

Best for:

- Internal reusable components.
- Local development and module testing.
- Project-specific infrastructure code.

```hcl
module "app_server" {
  source = "./modules/app_server"

  instance_type = "t3.micro"
}
```

### Registry module

A registry module is downloaded from the Terraform Registry or a private registry.

Best for:

- Reusing community or organization-approved modules.
- Faster infrastructure development.
- Standard implementations for common services.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

### Remote module

A remote module is sourced from a remote location such as GitHub, GitLab, Bitbucket, S3, or HTTP.

Best for:

- Sharing modules across teams or projects.
- Versioning through Git tags or branches.
- Centralized infrastructure standards.

```hcl
module "security_group" {
  source = "git::https://github.com/example/terraform-modules.git//security-group?ref=v1.2.0"

  name = "web-sg"
}
```

### Common module files

| File | Purpose |
|---|---|
| `main.tf` | Main resources. |
| `variables.tf` | Input variables. |
| `outputs.tf` | Output values. |
| `providers.tf` | Provider configuration. |
| `versions.tf` | Terraform and provider version constraints. |
| `README.md` | Documentation. |

### Module type summary

| Module type | Used for |
|---|---|
| Root module | Main Terraform entry point. |
| Child module | Reusable infrastructure block. |
| Local module | Modules stored locally. |
| Registry module | Public or private registry modules. |
| Remote module | Modules from Git, S3, HTTP, or similar remote sources. |

## Terraform State File

Question: What is the Terraform state file, and what happens if you delete it accidentally?

The Terraform state file is Terraform's record of the infrastructure it manages. By default, local state is named:

```text
terraform.tfstate
```

State maps Terraform configuration to real infrastructure resources, such as:

- AWS EC2 instances.
- Azure resource groups.
- Kubernetes resources.
- Databases.
- Networks.
- IAM roles.

Terraform uses state to know:

- Which resources already exist.
- Resource IDs from the cloud provider.
- Dependencies between resources.
- Current known resource attributes.
- What needs to be created, changed, or destroyed.

### Why state matters

Without state, Terraform may not know that existing infrastructure was already created by Terraform.

Example configuration:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t3.micro"
}
```

If the state is missing, Terraform may think this EC2 instance does not exist and try to create a new one.

### Where state is stored

| State type | Location |
|---|---|
| Local state | Stored on your machine as `terraform.tfstate`. |
| Remote state | Stored in a backend such as S3, Azure Storage, Google Cloud Storage, Terraform Cloud, or Consul. |

Remote state is recommended for teams.

### If state is deleted accidentally

Possible effects:

- Terraform may try to recreate existing resources.
- Duplicate infrastructure may be created.
- Existing resources may become unmanaged.
- `terraform plan` may show many resources to create.
- Outputs and resource references may be lost.
- Team workflows may break.

### Recovery options

1. Restore from backup.

   This is the best option.

   Terraform often creates a local backup:

   ```text
   terraform.tfstate.backup
   ```

   If using a remote backend, restore from backend version history such as S3 versioning, Azure Blob version history, or Terraform Cloud state history.

   Example local restore in PowerShell:

   ```powershell
   Copy-Item terraform.tfstate.backup terraform.tfstate
   ```

2. Pull remote state again.

   If using a remote backend and only the local copy is missing:

   ```bash
   terraform init
   terraform state pull > terraform.tfstate
   ```

   In many remote backend setups, Terraform will use remote state automatically after `terraform init`.

3. Import existing resources.

   If no backup exists, import existing infrastructure back into Terraform state. The import workflow is covered earlier in this file.

   Example:

   ```bash
   terraform import aws_instance.web i-0123456789abcdef0
   ```

   The resource must already exist in your Terraform configuration:

   ```hcl
   resource "aws_instance" "web" {
     ami           = "ami-123456"
     instance_type = "t3.micro"
   }
   ```

   Then run:

   ```bash
   terraform plan
   ```

### State file safety rules

- Do not run `terraform apply` immediately after losing state.
- Run `terraform plan` and review whether Terraform wants to recreate or destroy resources.
- Use a remote state backend.
- Enable versioning on backend storage.
- Enable state locking.
- Restrict access to state files.
- Do not commit `terraform.tfstate` to Git.
- Do not manually edit state unless necessary.
- Back up state regularly.
