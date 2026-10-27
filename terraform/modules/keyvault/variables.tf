variable "name" {
  description = "Globally unique Key Vault name (3-24 chars)."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "admin_group_object_id" {
  description = "Entra group that can manage secrets (Key Vault Secrets Officer)."
  type        = string
}

variable "enable_private_endpoint" {
  description = "Create a private endpoint and disable public access. Costs money per hour; use for demos."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
