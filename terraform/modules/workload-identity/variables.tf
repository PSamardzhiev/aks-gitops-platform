variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "namespace" {
  type = string
}

variable "service_account" {
  type = string
}

variable "keyvault_id" {
  description = "Key Vault the identity may read secrets from."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
