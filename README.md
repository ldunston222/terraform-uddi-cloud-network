# terraform-uddi-cloud-network

This Terraform module allocates a VPC/VNet container and subnets in **Infoblox BloxOne DDI (IPAM)**. It is intended as an example for multi-cloud network automation and will likely need to be customized to work in your environment.

### Terraform and provider versions
This module uses the `infobloxopen/bloxone` provider (see [main.tf](main.tf)).

## Example Usage
This module should be used with VPC/VNet modules published by major cloud providers to allocate and provision VPCs/VNets in the cloud. See the subfolders under the examples folder for examples of use with some cloud providers.

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

## Outputs
| Name | Description | Type |
| ---- | ----------- | ---- |
| vpc_cidr | CIDR of allocated VPC/VNet block. | `string` |
| subnet_cidr | Prefix length of allocated subnets. | `number` |
| subnet_address | Subnet network addresses (sorted). | `list(string)` |
