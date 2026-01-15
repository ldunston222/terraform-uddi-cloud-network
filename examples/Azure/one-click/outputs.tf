output "vpc_cidr" {
  description = "Allocated VNet CIDR from BloxOne."
  value       = module.uddi_cloud_network.vpc_cidr
}

output "subnet_cidr" {
  description = "Allocated subnet prefix length from BloxOne."
  value       = module.uddi_cloud_network.subnet_cidr
}

output "subnet_addresses" {
  description = "Allocated subnet network addresses (sorted) from BloxOne."
  value       = module.uddi_cloud_network.subnet_address
}

output "bloxone_dns_zone" {
  description = "BloxOne authoritative DNS zone details when dns_zone_fqdn is set."
  value       = module.uddi_cloud_network.dns_zone
}

output "bloxone_dns_hosts" {
  description = "BloxOne host FQDNs and allocated IPs when dns_zone_fqdn is set."
  value       = module.uddi_cloud_network.dns_hosts
}

output "azure_resource_group" {
  description = "Azure Resource Group name and id."
  value = {
    name = azurerm_resource_group.rg.name
    id   = azurerm_resource_group.rg.id
  }
}

output "azure_virtual_network" {
  description = "Azure VNet name and id."
  value = {
    name = azurerm_virtual_network.vnet.name
    id   = azurerm_virtual_network.vnet.id
    cidr = module.uddi_cloud_network.vpc_cidr
  }
}

output "azure_subnets" {
  description = "Azure subnet names and ids."
  value = [
    for k in sort(keys(azurerm_subnet.subnets)) : {
      name = azurerm_subnet.subnets[k].name
      id   = azurerm_subnet.subnets[k].id
      cidr = azurerm_subnet.subnets[k].address_prefixes[0]
    }
  ]
}

output "azure_vms" {
  description = "Demo VM details when azure_vm_enabled is true."
  value = var.azure_vm_enabled ? [
    for k in sort(keys(azurerm_linux_virtual_machine.vms)) : {
      name       = azurerm_linux_virtual_machine.vms[k].name
      id         = azurerm_linux_virtual_machine.vms[k].id
      private_ip = azurerm_network_interface.vm_nics[k].ip_configuration[0].private_ip_address
      public_ip  = var.azure_vm_public_ip ? try(azurerm_public_ip.vm_pips[k].ip_address, null) : null
      subnet_id  = azurerm_network_interface.vm_nics[k].ip_configuration[0].subnet_id
    }
  ] : []
}
