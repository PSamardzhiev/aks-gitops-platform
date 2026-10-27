variable "subscription_id" {
  description = "Azure subscription ID to deploy into (az account show --query id -o tsv)."
  type        = string
}

variable "location" {
  description = "Azure region for the state storage account."
  type        = string
  default     = "westeurope"
}

variable "project" {
  description = "Short project name, lowercase letters/digits only (used in resource names)."
  type        = string
  default     = "aksgitops"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 lowercase letters or digits."
  }
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the repository."
  type        = string
  default     = "PSamardzhiev"
}

variable "github_repo" {
  description = "GitHub repository name that will run the pipelines."
  type        = string
  default     = "aks-gitops-platform"
}

variable "budget_amount" {
  description = "Monthly budget in the subscription's billing currency. Alerts only; it does NOT stop spending."
  type        = number
  default     = 60
}

variable "budget_contact_emails" {
  description = "E-mail addresses that receive budget alerts."
  type        = list(string)
}
