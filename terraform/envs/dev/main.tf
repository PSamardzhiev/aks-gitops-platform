data "azurerm_client_config" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  name                       = "kv-${var.project}-${var.environment}-${var.unique_suffix}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admin_group_object_id      = var.aks_admin_group_object_id
  enable_private_endpoint    = var.enable_keyvault_private_endpoint
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id
  private_dns_zone_id        = module.network.keyvault_private_dns_zone_id
  tags                       = local.tags
}

module "aks" {
  source = "../../modules/aks"

  name_prefix            = local.name_prefix
  location               = var.location
  resource_group_name    = azurerm_resource_group.this.name
  subnet_id              = module.network.aks_subnet_id
  tenant_id              = data.azurerm_client_config.current.tenant_id
  admin_group_object_id  = var.aks_admin_group_object_id
  kubernetes_version     = var.kubernetes_version
  system_vm_size         = var.system_node_vm_size
  system_node_count      = var.system_node_count
  spot_node_pool_enabled = var.spot_node_pool_enabled
  tags                   = local.tags
}

# Identity used by the sample app (gitops/workloads/sample-app-keyvault) to read Key Vault.
module "workload_identity" {
  source = "../../modules/workload-identity"

  name                = "id-${local.name_prefix}-sample-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  oidc_issuer_url     = module.aks.oidc_issuer_url
  namespace           = "sample-app"
  service_account     = "sample-app-sa"
  keyvault_id         = module.keyvault.id
  tags                = local.tags
}

# --- GitOps bootstrap -------------------------------------------------------
# Terraform installs ArgoCD once; from then on ArgoCD owns everything under
# gitops/ (including upgrading itself, if you choose to add that later).

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  wait             = true
  timeout          = 900

  values = [yamlencode({
    # Small cluster: drop components we do not use.
    dex           = { enabled = false }
    notifications = { enabled = false }
  })]
}

resource "helm_release" "argocd_root_app" {
  name       = "argocd-root"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = "gitops/apps"
          directory      = { recurse = false }
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["CreateNamespace=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
