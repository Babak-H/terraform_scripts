terraform {
  required_version = ">= 1.0"

  required_providers {
    # here our provider is not AWS, but helm, since we need to download and apply some helm charts to our cluster
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.9"
    }
  }
}