# ADR 0004: ArgoCD bootstrapped by Terraform, then GitOps takes over

Status: draft (rewrite in your own words and adjust to what you actually decided)

## Context
Something must install ArgoCD before ArgoCD can manage anything. I also want one place to run from scratch.

## Decision
Terraform installs ArgoCD with two Helm releases: `argo-cd`, then `argocd-apps`, which creates a single **root
Application** (app-of-apps) pointing at `gitops/apps`. Every other component (sample app, Prometheus/Grafana,
Kyverno and its policies) is an Application in that folder. Terraform stays in one stack so a single pipeline
creates the cluster and bootstraps it.

## Consequences
- Adding a component means adding a manifest and merging; no Terraform change.
- To let Terraform install ArgoCD, AKS **local accounts are enabled** and the Helm provider uses the admin
  credential. This is the main security trade-off.
- Provider configuration depends on a resource created in the same run, which can fail on the very first plan
  (see runbook for the `-target` workaround).

## Follow-ups
- Disable local accounts: give the CI identity an AKS RBAC role and use kubelogin in the pipeline.
- Split into two stacks (cluster, then platform) to remove the first-plan limitation.
- Put the API server behind a private endpoint, reached from a self-hosted runner or the VPN.

## Alternatives considered
- Flux's `flux bootstrap`, or the AKS GitOps extension: managed and tidy, but hides what I want to show.
- Installing ArgoCD manually with `kubectl`: not reproducible.
