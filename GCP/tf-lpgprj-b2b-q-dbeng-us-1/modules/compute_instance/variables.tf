variable "node_count" {
  type        = number
  default     = 3
  description = "Number of compute instances to be created per region."
}

variable "resourcetype" {
  type        = string
  default     = "gcen"
  description = "Type of resource to be created"
}

variable "diskrestype" {
  type        = string
  default     = "gcen"
  description = "Type of resource to be created"
}
variable "env" {
  type        = string
  default     = "q"
  description = "(Required) Enviroment "

}

variable "dataDiskSize" {
  type        = number
  default     = 250
  description = "Disk size to used for code data"
}

variable "codeDiskSize" {
  type        = number
  default     = 100
  description = "Disk size to used for code mount"
}

variable "BootdiskSize" {
  type        = number
  default     = 50
  description = "Disk size to used for boot mount"
}

variable "project_id" {
  default     = "lpgprj-b2b-q-dbeng-us-1"
  description = "Project ID where compute instance are created."

}

variable "machine_type" {
  type        = string
  default     = "e2-standard-4"
  description = "(Required) Machine type to use"
}

variable "region" {
  type        = string
  default     = "us-east1"
  description = "Region where compute instances are created."

}

variable "zones" {
  type        = list(any)
  default     = ["us-east1-b", "us-east1-c", "us-east1-d"]
  description = "Zone where compute instances are created."
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "(Optional) To enable or disable deletion protection"
}

variable "vpc_network" {
  default     = "lpgvpc-h-b2b-npr-us-01"
  type        = string
  description = "VPC network for the project"
}

variable "subnetwork_project" {
  default     = "lpgprj-b2b-n-hostcc-us-01"
  type        = string
  description = "Subnet work shared by the project"
}

variable "labels" {
  type        = map(string)
  default     = { datastore = "kafka" }
  description = " Key/value label pairs for the instance"
}

variable "app" {
  type        = string
  default     = "gur"
  description = "(Required) Database type you plan on running on this compute"
}

variable "tags" {
  type        = list(string)
  default     = ["elasticsearch"]
  description = "Tags applied to all nodes. Tags are used to identify valid sources or targets for network firewalls."

}

variable "dbtype" {
  type        = string
  default     = "cass"
  description = "(Required) Database type you plan on running on this compute 3-5 dig abbreviation (cass,couch,kfk,zkp,els,mysql)"
}

variable "diskType" {
  type        = string
  default     = "pd-balanced"
  description = "Disk type"
}

variable "BootdiskType" {
  type        = string
  default     = "pd-ssd"
  description = "Disk type used for BootImages"
}

variable "image" {
  type        = string
  default     = "projects/lpgprj-gss-p-images-gl-01/global/images/custom-centos-7-v20230203-20230205-023529"
  description = "Base Image to be used to create compute instance"
}

variable "service_account" {
  default     = "lpgsac-q-comp-cass-us@lpgprj-b2b-q-dbeng-us-1.iam.gserviceaccount.com"
  type        = string
  description = "Service account to be attached to the instance"
}
