# ADR 0001: GitHub OIDC federation instead of stored credentials

Status: draft (rewrite in your own words and adjust to what you actually decided)

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
