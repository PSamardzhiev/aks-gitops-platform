#!/usr/bin/env bash
# Copies bootstrap outputs into GitHub repository variables (needs the gh CLI, logged in).
# usage: scripts/set-github-vars.sh OWNER/REPO UNIQUE_SUFFIX
set -euo pipefail

REPO="${1:?usage: $0 OWNER/REPO UNIQUE_SUFFIX}"
SUFFIX="${2:?usage: $0 OWNER/REPO UNIQUE_SUFFIX (3-6 lowercase letters/digits)}"

cd "$(dirname "$0")/../bootstrap"
out() { terraform output -raw "$1"; }

set_var() { gh variable set "$1" --repo "$REPO" --body "$2" && echo "set $1"; }

set_var AZURE_CLIENT_ID            "$(out client_id)"
set_var AZURE_TENANT_ID            "$(out tenant_id)"
set_var AZURE_SUBSCRIPTION_ID      "$(out subscription_id)"
set_var TFSTATE_RG                 "$(out tfstate_resource_group)"
set_var TFSTATE_SA                 "$(out tfstate_storage_account)"
set_var AKS_ADMIN_GROUP_OBJECT_ID  "$(out aks_admin_group_object_id)"
set_var UNIQUE_SUFFIX              "$SUFFIX"
