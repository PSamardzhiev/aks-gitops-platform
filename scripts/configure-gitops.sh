#!/usr/bin/env bash
# Fills the Key Vault demo manifests with values from the deployed environment.
# Run from anywhere after `terraform apply`; it needs the same TF_VAR_*/ARM_* setup as a local plan.
# usage: scripts/configure-gitops.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform/envs/dev"
TARGET="$ROOT/gitops/workloads/sample-app-keyvault"

out() { terraform -chdir="$TF_DIR" output -raw "$1"; }

KV_NAME="$(out keyvault_name)"
CLIENT_ID="$(out workload_identity_client_id)"
TENANT_ID="$(out tenant_id)"

sed -i \
  -e "s|__KEYVAULT_NAME__|${KV_NAME}|g" \
  -e "s|__WORKLOAD_IDENTITY_CLIENT_ID__|${CLIENT_ID}|g" \
  -e "s|__TENANT_ID__|${TENANT_ID}|g" \
  "$TARGET"/*.yaml

echo "Updated manifests in $TARGET:"
echo "  keyvault=$KV_NAME client_id=$CLIENT_ID tenant=$TENANT_ID"
echo "Next: create the secret, git mv the optional Application, commit and push (docs/runbook.md)."
