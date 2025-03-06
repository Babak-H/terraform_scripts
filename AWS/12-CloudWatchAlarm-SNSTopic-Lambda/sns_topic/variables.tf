variable "region" {
    description = "AWS Region in which to deploy the resources"
    type = string
    default = ""
}

variable "account_id" {
    description = "Account ID"
    type = string
    default = ""
}

variable "seal_id" {
    description = "Seal ID"
    type = string
    default = ""
}

variable "deployment_id" {
    description = "Deployment ID for the Environment"
    type = string
    default = ""
}

variable "environment" {
    description = "The environment we are running in"
    type        = string
    default     = "DEV"
}

# variable "sns_arn" {
#     value = aws_sns_topic.sns_topic.arn
# }

variable "kms_key_alias" {
    description = "The KMS Key alias used to encrypt this SNS topic"
    type = string
    default = ""
}

variable "topic_name" {
    description = "The name of the topic that is being created"
    type = string
    default = ""
}

variable "additional_policy" {
    description = "Additional Policy Object, when set provides additional permissions to this SNS topic"
    default = "{\"statement\": []}"
}

variable "tags" {
    description = "Expected tags for this object.  They are defaulted to 'UNKNOWN' to make it easy to identify tags on objects that need to be set."
    type = map(string)
    default = {
        "dev.res.for.id" = "UNKNOWN"
        "sys.res.appcomponent" = "SNS"
        "sys.res.appname" = "TOPIC"
        "sys.res.mon" = 1
        "protected" = false
    }
}

variable "allowed_accounts" {
    description = "List of account ID's within this environment that can access this topic"
    type = list(string)
    default = []
}