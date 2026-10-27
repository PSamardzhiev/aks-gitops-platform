# ADR 0002: Azure CNI Overlay with Cilium

Status: draft (rewrite in your own words and adjust to what you actually decided)

## Context
Pods need networking and the cluster should support network policies. The node subnet is small and I do not want
pod IPs to consume VNet address space.

## Decision
Azure CNI **Overlay** with the **Cilium** data plane and network policy engine. Pods get addresses from
`10.244.0.0/16` (not routable in the VNet); only nodes use the spoke subnet.

## Consequences
- Small subnet is enough; no IP exhaustion planning for pods.
- Network policies work out of the box, with Cilium visibility available later.
- Pods are not directly addressable from peered networks or on-prem; traffic goes through services/ingress or
  node IPs. Relevant for the future VPN phase.

## Alternatives considered
- Azure CNI (VNet-routable pods): simpler routing from on-prem, but needs a much larger subnet.
- kubenet: legacy, fewer features.
- Calico for policy: fine, but Cilium is the direction AKS is moving.
