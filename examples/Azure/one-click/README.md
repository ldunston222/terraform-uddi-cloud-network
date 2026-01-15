# Azure one-click example

This example is a wrapper root module that:
1. Calls the main module to allocate a VNet CIDR + subnets in BloxOne DDI (IPAM)
2. Creates an Azure Resource Group, Virtual Network, and Subnets using those CIDRs

## Run
From this folder (or from repo root using `-chdir`):
- `terraform init`
- `terraform plan`
- `terraform apply`

Notes:
- You must configure authentication for both providers:
  - `bloxone` (e.g., `BLOXONE_API_KEY` / `BLOXONE_CSP_URL`)
  - `azurerm` (Azure CLI login, env vars, managed identity, etc.)
- The example uses `demo.auto.tfvars` for inputs.

Recommended order (so auth works everywhere):
1) BloxOne auth (in your shell)
- `export BLOXONE_API_KEY='<your api key>'`
- `export BLOXONE_CSP_URL='https://csp.infoblox.com'` (or your CSP base URL)

2) Azure auth (Azure CLI)
- `az login`
- Optional but recommended: `az account set --subscription '<subscription id>'`

3) Run Terraform (from repo root)
- `terraform -chdir=examples/Azure/one-click init`
- `terraform -chdir=examples/Azure/one-click plan`
- `terraform -chdir=examples/Azure/one-click apply`

If you see an error like "subscription ID could not be determined":
- Set `azure_subscription_id` in `demo.auto.tfvars`, or
- Export `ARM_SUBSCRIPTION_ID` in your shell.
