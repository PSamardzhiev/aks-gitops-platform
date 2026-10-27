output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "aks_name" {
  value = module.aks.name
}

output "keyvault_name" {
  value = module.keyvault.name
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "workload_identity_client_id" {
  value = module.workload_identity.client_id
}

output "get_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.name} --admin"
}

output "argocd_port_forward" {
  value = "kubectl -n argocd port-forward svc/argocd-server 8080:443   # then https://localhost:8080 (user: admin)"
}
