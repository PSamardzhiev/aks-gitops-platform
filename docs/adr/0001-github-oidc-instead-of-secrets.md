# ADR 0001: GitHub OIDC federation instead of stored credentials

Status: superseded (2026-10-27)

## Context
GitHub Actions needs to deploy to Azure. My earlier AWS project (UpSkillDevOpsProject) used long-lived access
keys stored as repository secrets.

## Decision
Use an Entra ID app registration with **federated credentials**. Workflows request a short-lived token from
GitHub and exchange it for an Azure token. Three subjects are trusted: pull requests, the `main` branch, and the
`dev` environment (apply/destroy). No client secret exists.

## Consequences
- Nothing to leak or rotate; access is bound to this repository, branch and environment.
- The `dev` environment can require manual approval before apply.
- The identity has Contributor + User Access Administrator on the subscription so Terraform can create role
  assignments. Acceptable for a personal lab; for shared environments I would scope it to a resource group and use a
  constrained role-assignment permission.
- Pull-request plans use the same identity as apply. A read-only plan identity would be stricter.

## Alternatives considered
- Service principal secret in GitHub secrets: simpler, but long-lived and the exact weakness I wanted to remove.
- Self-hosted runner with a managed identity: strongest, but costs a VM and adds maintenance.

## Current implementation
The workflows now authenticate with an existing service principal using the
`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, and
`AZURE_SUBSCRIPTION_ID` GitHub Actions secrets. This is a deliberate operational
trade-off to use the available Terraform identity. The secret must be rotated
before expiry and the principal should have only the permissions the deployment
requires. The OIDC resources in `bootstrap/` are legacy and are not used by the
workflows.
