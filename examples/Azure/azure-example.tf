terraform {
  required_providers {
    bloxone = {
      source = "infobloxopen/bloxone"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "bloxone" {
  #For provider and authentication options for Infoblox, refer to: https://registry.terraform.io/providers/infobloxopen/infoblox/latest/docs
}

provider "azurerm" {
  #For provider and authentication options for Azure, refer to: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs 
  features {}
}

# Call the infoblox_cloud_network module with required variables
module "uddi_cloud_network" {
  source      = "../../"
  cloud       = "Azure"
  ip_space    = "Cloud-Staging"
  size        = "large"
  application = "test-app"
}
