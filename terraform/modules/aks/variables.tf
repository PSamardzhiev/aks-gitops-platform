variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Node subnet."
  type        = string
}

variable "tenant_id" {
  type = string
}

variable "admin_group_object_id" {
  description = "Entra group granted cluster-admin."
  type        = string
}

variable "kubernetes_version" {
  description = "null = AKS default for the region."
  type        = string
  default     = null
}

variable "system_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "system_node_count" {
  type    = number
  default = 1
}

variable "spot_node_pool_enabled" {
  description = "Adds an autoscaling Spot pool (0..spot_max_count). Spot nodes can be evicted; workloads need tolerations."
  type        = bool
  default     = false
}

variable "spot_vm_size" {
  type    = string
  default = "Standard_D2as_v5"
}

variable "spot_max_count" {
  type    = number
  default = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
