# Cost notes

Rough, order-of-magnitude figures for West Europe, pay-as-you-go. **Prices change: confirm with the
[Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) before relying on them.**

| Item | Billing | Notes |
|---|---|---|
| AKS control plane (Free tier) | no charge | No SLA; fine for a lab |
| System node (1x Standard_D2s_v5) | per hour while running | The main cost, on the order of tens of USD/month if left on 24/7 |
| Spot node pool (optional) | per hour, discounted | Can be evicted; scales to 0 |
| Key Vault | per operation | Negligible here |
| Private endpoint (optional) | per hour | Enable only for demos |
| Private DNS zone | per zone/month | Negligible |
| VNet peering | per GB transferred | Negligible here |
| Storage (tfstate) | per GB | Negligible |
| **VPN Gateway** (phase 2, not deployed) | per hour | Deploy only for a demo, then destroy |
| **Azure Firewall** (not deployed) | per hour, high | Hundreds of USD/month; skipped on purpose (ADR 0003) |

## Controls in this repo

- `bootstrap/` creates a monthly **budget** with alerts at 50% and 80% actual and 100% forecast. Alerts only warn; they do not stop resources.
- `aks-power` stops the cluster every evening (20:00 UTC). A stopped cluster does not bill for node VMs; disks and the public IP still cost a little.
- `terraform-destroy` removes the whole dev environment. Rebuilding takes roughly 15-25 minutes.

## Habits

- Check **Cost Management -> Cost analysis** weekly, grouped by resource group.
- Before leaving for a holiday: destroy, do not just stop.
