# One-time bootstrap. Run locally with `az login` (Owner on the subscription,
# and permission to create app registrations / groups in Entra ID).
# State for THIS folder is kept locally on purpose (chicken-and-egg): it holds
# the storage keys, so it is git-ignored. Back it up somewhere private.

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# --- Remote state ---------------------------------------------------------

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${var.project}-tfstate"
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "st${var.project}tf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 14
    }
  }

  # Hardening follow-up: set shared_access_key_enabled = false once the
  # container exists, so only Entra ID (RBAC) can access state.
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# --- GitHub Actions -> Azure via OIDC (no stored secrets) ------------------

resource "azuread_application" "github" {
  display_name = "sp-${var.project}-github-oidc"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

locals {
  github_subjects = {
    pull-request = "repo:${var.github_owner}/${var.github_repo}:pull_request"
    main-branch  = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
    env-dev      = "repo:${var.github_owner}/${var.github_repo}:environment:dev"
  }
}

resource "azuread_application_federated_identity_credential" "github" {
  for_each = local.github_subjects

  application_id = azuread_application.github.id
  display_name   = "github-${each.key}"
  description    = "GitHub Actions: ${each.value}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value
}

# Contributor + User Access Administrator: Terraform needs to create role
# assignments (AKS -> Key Vault, etc.). Acceptable for a personal lab
# subscription; scope down for anything shared. See docs/adr/0001.
resource "azurerm_role_assignment" "github_contributor" {
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_name             = "Contributor"
  principal_id                     = azuread_service_principal.github.object_id
  skip_service_principal_aad_check = true # new principals may not be visible in Entra yet
}

resource "azurerm_role_assignment" "github_uaa" {
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_name             = "User Access Administrator"
  principal_id                     = azuread_service_principal.github.object_id
  skip_service_principal_aad_check = true # new principals may not be visible in Entra yet
}

resource "azurerm_role_assignment" "github_state" {
  scope                            = azurerm_storage_account.tfstate.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azuread_service_principal.github.object_id
  skip_service_principal_aad_check = true # new principals may not be visible in Entra yet
}

# You need blob access too, to run Terraform locally against the same state.
resource "azurerm_role_assignment" "me_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.current.object_id
}

# --- AKS admin group (Entra ID) --------------------------------------------

resource "azuread_group" "aks_admins" {
  display_name     = "${var.project}-aks-admins"
  security_enabled = true
  owners           = [data.azuread_client_config.current.object_id]
  members          = [data.azuread_client_config.current.object_id]
}

# --- Budget alert ----------------------------------------------------------

resource "azurerm_consumption_budget_subscription" "lab" {
  name            = "budget-${var.project}"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
