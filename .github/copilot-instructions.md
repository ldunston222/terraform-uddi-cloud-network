# Copilot instructions (terraform-uddi-cloud-network)

## Big picture
- This repo is a Terraform module that allocates IP space for cloud networks in **Infoblox BloxOne DDI (IPAM)** using the `infobloxopen/bloxone` provider.
- Primary flow in [main.tf](../main.tf):
  - Lookup IP Space by name (`data.bloxone_ipam_ip_spaces`).
  - Find an existing parent container by `tag_filters = { Cloud = var.cloud }`.
  - Optionally create a parent pool (`var.parent_pool_cidr`) if none exists.
  - Allocate a VPC/VNet container (`bloxone_ipam_address_block.vpc_container`) from the parent via `next_available_id`.
  - Allocate subnets (`bloxone_ipam_subnet.subnets`) from the VPC container via `next_available_id`.

## Key conventions in this module
- Tags drive discovery + ownership:
  - Parent container discovery uses `Cloud = var.cloud`.
  - Allocated resources are tagged with `Cloud` and `Application`.
- “T-shirt sizing” is implemented via locals + maps:
- `var.size` must be one of `small|medium|large` ([variables.tf](../variables.tf)).
  - `local.subnet_count` is `2` for `small`, otherwise `4`.
  - Prefix lengths come from `var.vpc_size[var.size]` and `var.subnet_size[var.size]`.
- Preconditions are enforced with `terraform_data.validate` in [main.tf](../main.tf). Preserve this pattern when adding new required lookups.

## How to run (typical workflows)
- Format/validate from repo root:
  - `terraform fmt -recursive`
  - `terraform init`
  - `terraform validate`
- Plan/apply requires provider auth for BloxOne; examples assume env vars like `BLOXONE_API_KEY` and `BLOXONE_CSP_URL` (see [examples/helper_scripts/ip_list_helper.txt](../examples/helper_scripts/ip_list_helper.txt)).
- Quick local try:
- Edit [demo.auto.tfvars](../demo.auto.tfvars) (auto-loaded by Terraform), then run `terraform plan` / `terraform apply`.

## Examples and composition pattern
- This module is designed to be composed with cloud network modules:
  - AWS example: [examples/AWS/aws-example.tf](../examples/AWS/aws-example.tf) uses `module.uddi_cloud_network.vpc_cidr` and joins each subnet: `join("/", [subnet_address[i], subnet_cidr])`.
  - Azure example: [examples/Azure/azure-example.tf](../examples/Azure/azure-example.tf) passes `address_space = [module.uddi_cloud_network.vpc_cidr]` and enumerates 2 or 4 `subnet_prefixes`.
  - GCP example: [examples/GCP/gcp-example.tf](../examples/GCP/gcp-example.tf) requires an explicit object per subnet.

## Repo hygiene / gotchas
- Treat `.terraform/` as generated; don’t edit or commit changes there.
- This repo currently contains `terraform.tfstate` and `terraform.tfstate.backup` at the root; do not hand-edit these files and avoid including state changes in PRs unless that’s explicitly intended.
- If you change inputs/outputs or sizing behavior, update:
  - [README.md](../README.md) Inputs/Outputs tables
  - Cloud examples under [examples/](../examples/) (they hardcode the expected subnet count)
