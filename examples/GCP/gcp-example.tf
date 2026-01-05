terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
    }
    google = {
        source = "hashicorp/google"
    }
  }
}

provider "bloxone" {
#For provider and authentication options for Infoblox, refer to: https://registry.terraform.io/providers/infobloxopen/infoblox/latest/docs
}

provider "google" {
#For provider and authentication options for GCP, refer to: https://registry.terraform.io/providers/hashicorp/google/latest/docs
}
locals {
  gcp_region = "us-east1"
}

# Call the infoblox_cloud_network module with required variables
module "uddi_cloud_network" {
  source = "../../"
  cloud = "GCP"
  ip_space = "Cloud-Staging"
  size = "large"
  application = "test-app"
}

# Use the GCP network module to create VPC and Subnets: https://registry.terraform.io/modules/terraform-google-modules/network/google/latest
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "9.0.0"
  network_name = "auto-vpc"
  project_id = "gcp-pm-sandbox-east"
  subnets = [ # The GCP module requires a block for each subnet you will create. Adjust based on how many subnets are created: 2 for small, 4 for large and medium
    {
      subnet_name = "subnet-01"
      subnet_ip = join("/", [module.uddi_cloud_network.subnet_address[0], module.uddi_cloud_network.subnet_cidr])
      subnet_region = local.gcp_region
    },
    {
      subnet_name = "subnet-02"
      subnet_ip = join("/", [module.uddi_cloud_network.subnet_address[1], module.uddi_cloud_network.subnet_cidr])
      subnet_region = local.gcp_region
    },
    {
      subnet_name = "subnet-03"
      subnet_ip = join("/", [module.uddi_cloud_network.subnet_address[2], module.uddi_cloud_network.subnet_cidr])
      subnet_region = local.gcp_region
    },
    {
      subnet_name = "subnet-04"
      subnet_ip = join("/", [module.uddi_cloud_network.subnet_address[3], module.uddi_cloud_network.subnet_cidr])
      subnet_region = local.gcp_region
    }
  ]
}