# ADR 0003: Hub-and-spoke without Azure Firewall (for now)

Status: draft (rewrite in your own words and adjust to what you actually decided)

## Context
I want a layout that can grow into hybrid connectivity (VPN to a home lab) and central egress control, on a personal
budget. Azure Firewall and VPN Gateway bill hourly even when idle.

## Decision
Build the hub-and-spoke topology now (hub VNet, spoke VNet, peering both ways, reserved `GatewaySubnet` and
`AzureFirewallSubnet`) but deploy **no firewall or gateway** by default. Control inbound traffic with an NSG on the
AKS subnet.

## Consequences
- The address plan and peering are already correct, so adding a gateway or firewall does not mean re-IPing.
- No central egress filtering: nodes have direct outbound internet access.
- Expensive components are demoed briefly and destroyed.

## Alternatives considered
- Single VNet: cheaper and simpler, but would not demonstrate the hybrid design.
- Azure Firewall from day one: realistic, but disproportionate cost for a lab.
