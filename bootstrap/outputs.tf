output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  value = var.subscription_id
}

output "client_id" {
  description = "Client ID of the GitHub OIDC app registration."
  value       = azuread_application.github.client_id
}

output "tfstate_resource_group" {
  value = azurerm_resource_group.tfstate.name
}

output "tfstate_storage_account" {
  value = azurerm_storage_account.tfstate.name
}

output "aks_admin_group_object_id" {
  value = azuread_group.aks_admins.object_id
}
