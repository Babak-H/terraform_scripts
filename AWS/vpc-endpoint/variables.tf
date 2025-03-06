variable "aws_assume_role_pave" {
  description = "SpinnakerManagedRolePave/infradeployer role to use"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS Region in which to deploy the resource"
  type        = string
  default     = "eu-west-2"
}

variable "aws_service" {
  description = "AWS Service for VPC endpoint"
  type        = string
  default     = ""
}

variable "seal_id" {
  description = "SEAL ID for the object being created"
  type        = string
  default     = "105250"
}

variable "deployment_id" {
  description = "Deployment ID for environment into which the object is being deployed"
  type        = string
  default     = "0000gb"
}

variable "friendly_name" {
  description = "A friendly name that can be added to the object name"
  type        = string
  default     = ""
}

variable "use_guid" {
  description = "Determines where a guid will be appended to the object name, default is true.  This is normally used when creating core objects that will be used across multiple sub-modules (e.g. to simlify referring to these objects by name)"
  type = bool
  default = true
}

variable "environment" {
  description = "Environment the object is deployed to"
  type        = string
  default     = ""
}

variable "has_private_subnets" {
  description = "Determines whether the VPC endpoint will use Private or Public Subnets."
  type        = string
  default     = "true"
}

variable "is_privatelink" {
  description = "Determines whether the VPC Endpoint being created is a PrivateLink endpoint."
  type        = string
  default     = "false"
}

variable "enabled" {
  description = "Simulates a count=0 for this module"
  type        = string
  default     = "true"
}

variable "external_sg_groups" {
    description = "List Variable to pass in external Security groups to associate with VPC"
    type = list(string)
    default = []
}

##-- Tagging Values --##
variable "fin_res_chg_id" {
  description = "Charge code for use by finance"
  default     = ""
}

variable "dev_res_for_id" {
  description = "Seal ID"
  default     = ""
}

variable "sys_res_appcomponent" {
  description = "Application Component"
  default     = "VPC ENDPOINT"
}

variable "dyn_res_appcomponent" {
  description = "Application Component"
  default     = "VPC ENDPOINT"
}

variable "sys_res_appname" {
  description = "Application Name"
  default     = "ENDPOINT"
}

variable "dyn_res_appname" {
  description = "Application Name"
  default     = "ENDPOINT"
}

variable "sys_res_mon" {
  description = "Monitoring"
  default     = 1
}

variable "dyn_res_mon" {
  description = "Monitoring"
  default     = 1
}

variable "sys_res_env" {
  description = "Environment Type - DEV/TEST/PROD"
  default     = "UNKNOWN"
}

variable "dyn_res_env" {
  description = "Environment Type - D/E/I/N/P CORE..."
  default     = "UNKNOWN"
}

variable "ami_build_id" {
  description = "ID of the AMI"
  default     = "UNKNOWN"
}

variable "protected" {
  description = "This is an instance that should not be terminated"
  default     = "false"
}

variable "release_version" {
  description = "Release version of the code deployed"
  default     = "UNKNOWN"
}

variable "dev_res_data_class" {
  description = "Data Classification"
  default     = "UNKNOWN"
}

variable "tag_description" {
  description = "VPC Endpoint tag description - Optional"
  type        = string
  default     = ""
}