variable "eks_oidc_root_ca_thumbprint" {
  type = string
  description = "Thumbprint of Root CA for EKS OIDC, valid until 2037"
  default = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}