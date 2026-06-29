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
Terraform runs in the context of a folder (root module): it loads all `*.tf` in that directory.

Important architecture note:
- The repo root is the reusable BloxOne allocation module.
- The one-click cloud demos are separate root modules under `examples/*/one-click/`.
- To run AWS + Azure + GCP one-click scenarios, run each wrapper root module (sequentially), rather than changing the repo-root module to orchestrate all three.

1) Authenticate for BloxOne (shell environment variables)
- `export BLOXONE_API_KEY='<your api key>'`
- `export BLOXONE_CSP_URL='https://csp.infoblox.com'` (or your CSP base URL)

Notes on variable names:
- Some environments/tools use `CSP_API_KEY` / `CSP_URL` instead of `BLOXONE_API_KEY` / `BLOXONE_CSP_URL`.
- This repo (and `infobloxopen/bloxone`) commonly use the `BLOXONE_*` names. If you only have `CSP_API_KEY` set, you can map it for Terraform:
  - `export BLOXONE_API_KEY="${BLOXONE_API_KEY:-$CSP_API_KEY}"`
  - `export BLOXONE_CSP_URL="${BLOXONE_CSP_URL:-${CSP_URL:-https://csp.infoblox.com}}"`

Quick auth sanity check (should return `HTTP 200`):
- `curl -sS -o /dev/null -w "HTTP %{http_code}\n" -H "Authorization: Token ${BLOXONE_API_KEY}" "${BLOXONE_CSP_URL%/}/api/ddi/v1/ipam/ip_space"`
  - `401` usually means the token is missing/invalid.
  - `403` usually means the token is valid but lacks permissions for the operation.

Important: Terraform only sees environment variables exported in the same shell session (or configured in your terminal/CI environment).

2) Authenticate for Azure (Azure CLI)
- `az login`
- Optional but recommended: `az account set --subscription '<subscription id>'`
- If Terraform can’t infer the subscription: set `azure_subscription_id` in `examples/Azure/one-click/demo.auto.tfvars` or export `ARM_SUBSCRIPTION_ID`.

3) Authenticate for AWS (AWS CLI)
- `aws configure`
or set environment variables:
- `export AWS_ACCESS_KEY_ID='<your access key>'`
- `export AWS_SECRET_ACCESS_KEY='<your secret key>'`
- `export AWS_DEFAULT_REGION='us-west-2'`

4) Authenticate for GCP (gcloud)
- `gcloud auth application-default login`
- `gcloud config set project '<your-gcp-project-id>'`

5) Run Terraform from the folder you intend to apply
- AWS “one-click” wrapper (allocates in BloxOne + creates AWS resources):
  - `terraform -chdir=examples/AWS/one-click init`
  - `terraform -chdir=examples/AWS/one-click plan`
  - `terraform -chdir=examples/AWS/one-click apply`
- Azure “one-click” wrapper (allocates in BloxOne + creates Azure resources):
  - `terraform -chdir=examples/Azure/one-click init`
  - `terraform -chdir=examples/Azure/one-click plan`
  - `terraform -chdir=examples/Azure/one-click apply`
- GCP “one-click” wrapper (allocates in BloxOne + creates GCP resources):
  - `terraform -chdir=examples/GCP/one-click init`
  - `terraform -chdir=examples/GCP/one-click plan`
  - `terraform -chdir=examples/GCP/one-click apply`

To run all three one-click scenarios from repo root, execute:
- `terraform -chdir=examples/AWS/one-click init && terraform -chdir=examples/AWS/one-click apply`
- `terraform -chdir=examples/Azure/one-click init && terraform -chdir=examples/Azure/one-click apply`
- `terraform -chdir=examples/GCP/one-click init && terraform -chdir=examples/GCP/one-click apply`

Or use the helper script (sequentially runs AWS, Azure, then GCP one-click roots):
- `./examples/helper_scripts/run-all-one-click.sh plan`
- `./examples/helper_scripts/run-all-one-click.sh apply -- -auto-approve`
- `./examples/helper_scripts/run-all-one-click.sh destroy -- -auto-approve`

If you only want to allocate IPAM/DNS objects in BloxOne (no cloud resources), run Terraform from the repo root (this module) in a separate scratch/root module that calls it.

## Example Usage
This module should be used with VPC/VNet modules published by major cloud providers to allocate and provision VPCs/VNets in the cloud. See the subfolders under the examples folder for examples of use with some cloud providers.

For an end-to-end Azure wrapper that allocates CIDRs in BloxOne and then creates the Azure Resource Group/VNet/Subnets, see `examples/Azure/one-click/`.

For an end-to-end AWS wrapper that allocates CIDRs in BloxOne and then creates the VPC/Subnets (and optional demo EC2 instances), see `examples/AWS/one-click/`.

For an end-to-end GCP wrapper that allocates CIDRs in BloxOne and then creates the VPC/Subnets (and optional demo GCE VMs), see `examples/GCP/one-click/`.

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
