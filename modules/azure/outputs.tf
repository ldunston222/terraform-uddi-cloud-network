output "resource_group" {
  value = !var.enabled ? null : {
    id       = azurerm_resource_group.rg[0].id
    name     = azurerm_resource_group.rg[0].name
    location = azurerm_resource_group.rg[0].location
  }
}

output "vnet" {
  value = !var.enabled ? null : {
    id            = azurerm_virtual_network.vnet[0].id
    name          = azurerm_virtual_network.vnet[0].name
    address_space = azurerm_virtual_network.vnet[0].address_space
  }
}

output "subnets" {
  value = !var.enabled ? [] : [
    for s in azurerm_subnet.subnets : {
      id               = s.id
      name             = s.name
      address_prefixes = s.address_prefixes
    }
  ]
}
