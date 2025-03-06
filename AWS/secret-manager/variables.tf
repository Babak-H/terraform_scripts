variable "region" {
  type        = string
  description = "The region the resource is deployed to"
  default     = "eu-west-2"
}

variable "environment" {
  type        = string
  description = "The environment we are running in, e.g. D,I,E"
  default     = "D"
}

variable "description" {
  type        = string
  description = "The Description of this Secret"
  default     = "Example secret"
}

variable "use_guid" {
  type        = bool
  description = "Determines where a guid will be appended to the object name, default is true."
  default     = true
}

variable "secret_name" {
  type        = string
  description = "The name of the true Secret being created."
  default     = "example-secret"
}

variable "secret_string" {
  type        = string
  description = "The data that you want to encrypt and store in the secret."
  default     = "simple-example-secret-string"
}

variable "rotation_frequency" {
  type        = number
  description = "This specifies the number of days between automatic scheduled rotations of the secret."
  default     = 28
}

variable "recovery_window_in_days" {
  type        = number
  description = "The number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days."
  default     = 0
}

variable "kms_key_id" {
  type        = string
  description = "The ID or alias for the KMS encryption key."
}

variable "postgres_password" {
  type        = string
  description = "True or false input only. If true, the secret will be connected to the rotation lambda"
  default     = "false"
}

variable "seal_id" {
  type        = string
  description = "SEAL id."
}

variable "deployment_id" {
  type        = string
  description = "Deployment ID for the Environment"
}

variable "tags" {
  type        = map(string)
  description = "ICB tags to apply to resources."
  default = {
    "dev.res.for.id"       = "UNKNOWN"
    "sys.res.appcomponent" = "SECRETS MANAGER"
    "dyn.res.appcomponent" = "SECRETS MANAGER"
    "sys.res.appname"      = "SECRET"
    "dyn.res.appname"      = "SECRET"
    "sys.res.env"          = "UNKNOWN"
    "dyn.res.env"          = "UNKNOWN"
    "sys.res.mon"          = "1"
    "dyn.res.mon"          = "1"
    "dev.res.data.class"   = "UNKNOWN"
    "release.version"      = "UNKNOWN"
    "protected"            = "false"
  }
}

variable "stage" {
  type        = string
  description = "Terraform stage that is currently executing, e.g. plan, apply"
  default     = ""
}
