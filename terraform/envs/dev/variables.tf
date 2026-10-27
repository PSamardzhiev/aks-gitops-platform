variable "project" {
  type    = string
  default = "aksgitops"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "unique_suffix" {
  description = "3-6 lowercase letters/digits that make the Key Vault name globally unique (e.g. your initials + digits)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,6}$", var.unique_suffix))
    error_message = "unique_suffix must be 3-6 lowercase letters or digits."
  }
}

variable "aks_admin_group_object_id" {
  description = "Object ID of the Entra group created by bootstrap/."
  type        = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "system_node_count" {
  type    = number
  default = 1
}

variable "spot_node_pool_enabled" {
  type    = bool
  default = false
}

variable "enable_keyvault_private_endpoint" {
  description = "Demo toggle: private endpoint + public access off. Costs extra per hour."
  type        = bool
  default     = false
}

variable "gitops_repo_url" {
  type    = string
  default = "https://github.com/PSamardzhiev/aks-gitops-platform.git"
}

variable "gitops_revision" {
  type    = string
  default = "main"
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version. Check https://github.com/argoproj/argo-helm/releases and bump deliberately."
  type        = string
  default     = "10.1.3"
}

variable "argocd_apps_chart_version" {
  description = "argocd-apps Helm chart version (creates the root app-of-apps)."
  type        = string
  default     = "2.0.4"
}
