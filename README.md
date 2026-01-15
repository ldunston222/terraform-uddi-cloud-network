# terraform-uddi-cloud-network

This Terraform module allocates a VPC/VNet container and subnets in **Infoblox BloxOne DDI (IPAM)**. It is intended as an example for multi-cloud network automation and will likely need to be customized to work in your environment.

### Terraform and provider versions
This module uses the `infobloxopen/bloxone` provider (see [main.tf](main.tf)).

## Prerequisites (BloxOne)
- An IP Space named exactly `ip_space` must already exist.
- A parent address block to allocate from must exist in that IP Space and be discoverable via tags `Cloud = <Azure|AWS|GCP>` and `Role = parent-pool`, OR set `parent_pool_cidr` to let Terraform create that parent pool.
- Your BloxOne API key must have permissions to read IP Spaces/address blocks and create address blocks/subnets.

## Optional prerequisites (Azure)
- This module does not create Azure resources directly. See `examples/Azure/` for an example of composing this module with Azure resources in a calling root module.

## Typical workflow
From the repo root:
- `terraform fmt -recursive`
- `terraform init`
- `terraform plan`
- `terraform apply`

Provider authentication is environment-specific; one common pattern is using `BLOXONE_API_KEY` and `BLOXONE_CSP_URL` (see `examples/helper_scripts/ip_list_helper.txt`).

## Quickstart (auth + folder order)
Terraform runs in the context of a folder (root module): it loads all `*.tf` in that directory. Most users should run the Azure demo from `examples/Azure/one-click/`, not from the repo root.

1) Authenticate for BloxOne (shell environment variables)
- `export BLOXONE_API_KEY='<your api key>'`
- `export BLOXONE_CSP_URL='https://csp.infoblox.com'` (or your CSP base URL)

2) Authenticate for Azure (Azure CLI)
- `az login`
- Optional but recommended: `az account set --subscription '<subscription id>'`
- If Terraform can’t infer the subscription: set `azure_subscription_id` in `examples/Azure/one-click/demo.auto.tfvars` or export `ARM_SUBSCRIPTION_ID`.

3) Run Terraform from the folder you intend to apply
- Azure “one-click” wrapper (allocates in BloxOne + creates Azure resources):
  - `terraform -chdir=examples/Azure/one-click init`
  - `terraform -chdir=examples/Azure/one-click plan`
  - `terraform -chdir=examples/Azure/one-click apply`

If you only want to allocate IPAM/DNS objects in BloxOne (no cloud resources), run Terraform from the repo root (this module) in a separate scratch/root module that calls it.

## Example Usage
This module should be used with VPC/VNet modules published by major cloud providers to allocate and provision VPCs/VNets in the cloud. See the subfolders under the examples folder for examples of use with some cloud providers.

For an end-to-end Azure wrapper that allocates CIDRs in BloxOne and then creates the Azure Resource Group/VNet/Subnets, see `examples/Azure/one-click/`.

```hcl
module "uddi_cloud_network" {
  source      = "github.com/infobloxopen/terraform-uddi-cloud-network"
  ip_space    = "Cloud-Staging"
  cloud       = "Azure"
  size        = "large"
  application = "test-app"
}
```

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :--------: |
| ip_space | IP Space name in BloxOne (must exist; exact match). | `string` | N/A | Yes |
| parent_pool_cidr | Optional: create a parent pool (address block) if none exists for Cloud tag (example: `172.16.0.0/16`). | `string` | `null` | No |
| cloud | Cloud provider tag used for discovery/ownership (`Azure`, `AWS`, `GCP`). | `string` | N/A | Yes |
| size | T-shirt size of VPC/VNet container: `small`, `medium`, `large`. | `string` | N/A | Yes |
| application | Application tag applied to allocated resources. | `string` | N/A | Yes |
| subnet_extra_tags | Optional per-subnet tag maps (by index). Must be empty or match subnet count (2 for `small`, 4 otherwise). | `list(map(string))` | `[]` | No |
| dns_zone_fqdn | Optional: when set, create a BloxOne authoritative DNS zone. | `string` | `null` | No |
| dns_hostnames | Optional: hostnames to create as A records in `dns_zone_fqdn` (defaults to `app-01..03`). | `list(string)` | `[]` | No |
| host_subnet_selector_tags | When `dns_zone_fqdn` is set, merged tags used to select exactly one subnet for host IPs. | `map(string)` | `{}` | No |
| host_ip_start_offset | When `dns_zone_fqdn` is set, start allocating host IPs at this cidrhost offset inside the selected subnet (default `4` to avoid cloud-reserved IPs). | `number` | `4` | No |

## Outputs
| Name | Description | Type |
| ---- | ----------- | ---- |
| vpc_cidr | CIDR of allocated VPC/VNet block. | `string` |
| subnet_cidr | Prefix length of allocated subnets. | `number` |
| subnet_address | Subnet network addresses (sorted). | `list(string)` |
| subnets | Subnets in count order with ids and tags. | `list(object)` |
| dns_zone | DNS zone details when `dns_zone_fqdn` is set. | `object` |
| dns_hosts | Host FQDNs and allocated IPs when `dns_zone_fqdn` is set. | `list(object)` |
