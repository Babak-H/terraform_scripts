variable "lp_context" {
  type = object({
    project_id      = string
    project_no      = string
    team_name       = string
    business_unit   = string
    cost_center_id  = string
    requester_id    = string
    request_no      = string
    platform_name   = optional(string)
    environment     = string
    geolocation     = string
    product_name    = optional(string)
    host_project_id = optional(string)
  })
  validation {
    condition     = can(regex("^(dev|qa|alpha|sandbox|production|shared)$", var.lp_context.environment)) && can(regex("^(global|au|eu|us)$", var.lp_context.geolocation))
    error_message = "Please check that environment is `dev, qa, alpha, sandbox, production, or shared` and geolocation is `global, au, eu, or us`."
  }
  description = "Object with meta data about the workspace and project. The info is used for naming conventions for internal modules and for labeling/tagging purposes on public cloud resources."
}

variable "dbtype" {
  type        = string
  default     = "mysql"
  description = "(Required) Database type you plan on running on this compute 3-5 dig abbreviation (mysql,cass,couch,kfk,zkp,els,mysql)"
}