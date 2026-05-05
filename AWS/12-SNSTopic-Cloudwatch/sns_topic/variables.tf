variable "region" {
  description = "AWS Region in which to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "Account ID"
  type        = string
  default     = ""
}

variable "seal_id" {
  description = "Seal ID"
  type        = string
  default     = ""
}

variable "deployment_id" {
  description = "Deployment ID for the Environment"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment we are running in"
  type        = string
  default     = "DEV"
}

variable "kms_key_alias" {
  description = "The KMS key alias used to encrypt this SNS topic. Use null for AWS managed encryption."
  type        = string
  default     = null
}

variable "topic_name" {
  description = "The name of the topic that is being created"
  type        = string
  default     = "sns-topic-1-0-5"
}

variable "additional_policy" {
  description = "Additional IAM policy JSON to merge into the SNS topic policy."
  type        = string
  default     = null
}

variable "tags" {
  description = "Expected tags for this object. They default to UNKNOWN so unset tags are easy to identify."
  type        = map(string)
  default = {
    "dev.res.for.id"       = "UNKNOWN"
    "sys.res.appcomponent" = "SNS"
    "sys.res.appname"      = "TOPIC"
    "sys.res.mon"          = "1"
    "protected"            = "false"
  }
}

variable "allowed_accounts" {
  description = "List of account IDs within this environment that can access this topic. Defaults to the current AWS account."
  type        = list(string)
  default     = []
}
