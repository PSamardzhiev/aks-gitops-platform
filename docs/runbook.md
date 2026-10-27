# Runbook

## First apply from your laptop (alternative to the pipeline)

```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
cd terraform/envs/dev

terraform init \
  -backend-config="resource_group_name=$(terraform -chdir=../../../bootstrap output -raw tfstate_resource_group)" \
  -backend-config="storage_account_name=$(terraform -chdir=../../../bootstrap output -raw tfstate_storage_account)"

cp terraform.tfvars.example terraform.tfvars   # set unique_suffix and aks_admin_group_object_id
terraform plan
terraform apply
```

If the first plan fails with *Kubernetes cluster unreachable*, the Helm provider cannot be configured
before the cluster exists. Create the cluster first, then everything else:

```bash
terraform apply -target=module.aks
terraform apply
```

After the first successful `terraform init`, commit `.terraform.lock.hcl` (it pins provider versions).

## Access the cluster

```bash
$(terraform output -raw get_credentials_command)
kubectl get nodes
kubectl get applications -n argocd
```

## ArgoCD

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 8080:443
# https://localhost:8080  user: admin
```

Expected after a few minutes: `root`, `sample-app`, `kube-prometheus-stack`, `kyverno`, `kyverno-policies` all Synced/Healthy.

## Grafana

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000  user: admin  (default password comes from the chart; change it on first login)
```

## Key Vault + workload identity demo

1. Fill the manifests with real values: `scripts/configure-gitops.sh`
2. Create the secret (you are in the admin group, which has *Key Vault Secrets Officer*; role propagation can take a few minutes):
   ```bash
   az keyvault secret set --vault-name "$(terraform -chdir=terraform/envs/dev output -raw keyvault_name)" \
     --name demo-secret --value "hello-from-keyvault"
   ```
3. Enable the Application and push:
   ```bash
   git mv gitops/optional/sample-app-keyvault.yaml gitops/apps/
   git add -A && git commit -m "Enable Key Vault demo" && git push
   ```
4. Verify:
   ```bash
   kubectl -n sample-app exec deploy/podinfo-keyvault -- cat /mnt/secrets/demo-secret
   ```

## Kyverno policy reports (Audit mode)

```bash
kubectl get policyreport -A
kubectl get clusterpolicy
```
Switch a policy to `Enforce` only after the reports are clean.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Terraform init or Azure login reports missing client credentials | GitHub Actions secrets are absent or unavailable to the workflow | Configure `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` in repository Actions secrets |
| `AuthorizationFailed` for role assignments | Service principal lacks permission to create role assignments | Grant the principal an appropriate role-assignment permission at the required scope |
| Key Vault name already in use / soft-deleted | Names are global; deleted vaults are retained | Change `unique_suffix`, or `az keyvault purge --name <name>` |
| VM size / quota error during AKS create | Region or subscription quota | `az vm list-usage -l westeurope -o table`; change `system_node_vm_size` or `location` |
| Plan fails with *cluster unreachable* | Helm provider before cluster exists | `terraform apply -target=module.aks`, then full apply |
| `kyverno-policies` shows *no matches for kind ClusterPolicy* | Policies synced before Kyverno CRDs | Wait: sync waves and retry resolve it; or hit Sync on `kyverno` first |
| State lock error | Previous run was interrupted | Confirm nothing is running, then `terraform force-unlock <LOCK_ID>` |
| Pods Pending on Spot pool | Spot taint | Add a toleration for `kubernetes.azure.com/scalesetpriority=spot` |
| Prometheus restarts (OOMKilled) | Single small node | Raise its memory limit in `gitops/apps/kube-prometheus-stack.yaml` or add a node |
| ArgoCD cannot fetch the repo | Repo is private | Make it public or add repository credentials to ArgoCD |

## Tear down

Actions -> **terraform-destroy** -> type `destroy`. The bootstrap resources (state, legacy OIDC app, group,
budget) remain; remove them with `terraform destroy` in `bootstrap/` when you are completely done.
