terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.15.0"
    }
  }

  experiments = [module_variable_optional_attrs]
}

provider "google" {
  project = "lpgprj-b2b-q-dbeng-us-1"
}
