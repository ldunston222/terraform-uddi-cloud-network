terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
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
  source = "../../"
  cloud = "Azure"
  ip_space = "Cloud-Staging"
  size = "large"
  application = "test-app"
}

# Create resource group in Azure
resource "azurerm_resource_group" "rg" {
  location = "westus"
  name = "autotest-rg"
}

# Use the Azure vnet module to create VNet and Subnets: https://registry.terraform.io/modules/Azure/vnet/azurerm/latest 
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name = "Auto-VNet"
  use_for_each = true
  vnet_location = azurerm_resource_group.rg.location 
  address_space = [ module.uddi_cloud_network.vpc_cidr ]
  subnet_prefixes = [ join("/", [module.uddi_cloud_network.subnet_address[0], module.uddi_cloud_network.subnet_cidr]),join("/", [module.uddi_cloud_network.subnet_address[1], module.uddi_cloud_network.subnet_cidr]), join("/", [module.uddi_cloud_network.subnet_address[2], module.uddi_cloud_network.subnet_cidr]), join("/", [module.uddi_cloud_network.subnet_address[3], module.uddi_cloud_network.subnet_cidr]) ] # Enter address input for each subnet - 2 for small, 4 for medium and large
  subnet_names = [ "subnet1", "subnet2", "subnet3", "subnet4" ] # Enter names for each subnet - 2 for small, 4 for medium and large
}