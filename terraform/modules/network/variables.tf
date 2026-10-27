variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "hub_address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "spoke_address_space" {
  type    = list(string)
  default = ["10.20.0.0/16"]
}

variable "aks_subnet_cidr" {
  type    = string
  default = "10.20.0.0/22"
}

variable "private_endpoint_subnet_cidr" {
  type    = string
  default = "10.20.4.0/24"
}

variable "tags" {
  type    = map(string)
  default = {}
}
