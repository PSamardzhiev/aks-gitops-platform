# Control-plane identity is user-assigned so it can be granted Network
# Contributor on the subnet BEFORE the cluster is created.
resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "id-${var.name_prefix}-aks-cp"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "control_plane_network" {
  scope                            = var.subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.control_plane.principal_id
  skip_service_principal_aad_check = true # new principals may not be visible in Entra yet
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  automatic_upgrade_channel = "patch"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Kept enabled so Terraform can bootstrap ArgoCD with the admin credential.
  # Hardening follow-up in docs/adr/0004-argocd-bootstrap-via-terraform.md
  local_account_disabled = false

  default_node_pool {
    name                        = "system"
    vm_size                     = var.system_vm_size
    node_count                  = var.system_node_count
    vnet_subnet_id              = var.subnet_id
    os_disk_size_gb             = 64
    temporary_name_for_rotation = "systemtmp"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.control_plane.id]
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.admin_group_object_id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    load_balancer_sku   = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.control_plane_network]
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = var.spot_node_pool_enabled ? 1 : 0

  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.spot_vm_size
  vnet_subnet_id        = var.subnet_id
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1
  auto_scaling_enabled  = true
  min_count             = 0
  max_count             = var.spot_max_count
  node_labels           = { "workload" = "spot" }
  node_taints           = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
  tags                  = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

# Lets the admin group run `az aks get-credentials`.
resource "azurerm_role_assignment" "admins_cluster_user" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.admin_group_object_id
}
