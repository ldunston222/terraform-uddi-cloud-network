terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  count = var.enabled ? 1 : 0

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  count = var.enabled ? 1 : 0

  name                = var.vnet_name
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  address_space = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "subnets" {
  depends_on = [terraform_data.validate]
  count      = var.enabled ? length(var.subnet_names) : 0

  name                 = var.subnet_names[count.index]
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.vnet[0].name

  address_prefixes = [var.subnet_prefixes[count.index]]
}

resource "terraform_data" "validate" {
  input = "validate"

  lifecycle {
    precondition {
      condition     = length(var.subnet_names) == length(var.subnet_prefixes)
      error_message = "subnet_names and subnet_prefixes must be the same length"
    }
  }
}
