terraform {
  required_version = ">= 1.4.0"

  required_providers {
    bloxone = {
      source = "infobloxopen/bloxone"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "bloxone" {
  # For provider and authentication options for Infoblox, refer to:
  # https://registry.terraform.io/providers/infobloxopen/bloxone/latest/docs
}

provider "azurerm" {
  # For provider and authentication options for Azure, refer to:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
  features {}

  subscription_id = var.azure_subscription_id
}

locals {
  base_tags = merge(
    {
      Cloud       = "Azure"
      Application = var.application
    },
    var.azure_extra_tags
  )
}

module "uddi_cloud_network" {
  source = "../../../"

  ip_space         = var.ip_space
  parent_pool_cidr = var.parent_pool_cidr

  cloud       = "Azure"
  size        = var.size
  application = var.application

  subnet_extra_tags         = var.subnet_extra_tags
  dns_zone_fqdn             = var.dns_zone_fqdn
  dns_hostnames             = var.dns_hostnames
  host_subnet_selector_tags = var.host_subnet_selector_tags
}

resource "terraform_data" "validate" {
  input = "validate"

  lifecycle {
    precondition {
      condition     = length(var.azure_subnet_names) == 0 || length(var.azure_subnet_names) == local.subnet_count
      error_message = "If azure_subnet_names is set, it must be empty or have exactly ${local.subnet_count} elements (one per subnet)."
    }

    precondition {
      condition = var.azure_vm_enabled == false || (
        coalesce(var.azure_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) != null &&
        coalesce(var.azure_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) >= 0 &&
        coalesce(var.azure_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) < local.subnet_count
      )
      error_message = "When azure_vm_enabled is true, the effective VM subnet index must be in range 0..${local.subnet_count - 1} for size='${var.size}'. Set azure_vm_subnet_index explicitly or ensure host_subnet_selector_tags selects a valid subnet."
    }

    precondition {
      condition     = var.azure_vm_enabled == false || var.dns_zone_fqdn != null
      error_message = "When azure_vm_enabled is true, dns_zone_fqdn must be set so VM IPs can be allocated in BloxOne and published in DNS (Option A)."
    }

    precondition {
      condition     = var.azure_vm_enabled == false || var.azure_vm_count == length(local.vm_hostnames_effective)
      error_message = "When azure_vm_enabled is true, azure_vm_count must equal the number of effective dns_hostnames (${length(local.vm_hostnames_effective)})."
    }
  }
}

locals {
  subnet_count = var.size == "small" ? 2 : 4

  dns_zone_fqdn_normalized = var.dns_zone_fqdn == null ? null : trimsuffix(var.dns_zone_fqdn, ".")

  vm_hostnames_effective = var.dns_zone_fqdn == null ? [] : (
    length(var.dns_hostnames) > 0 ? var.dns_hostnames : ["app-01", "app-02", "app-03"]
  )

  subnet_names = length(var.azure_subnet_names) > 0 ? var.azure_subnet_names : [
    for i in range(local.subnet_count) : format("subnet-%02d", i + 1)
  ]

  subnet_cidrs = [
    for i in range(local.subnet_count) : join("/", [module.uddi_cloud_network.subnets[i].address, tostring(module.uddi_cloud_network.subnets[i].cidr)])
  ]
}

resource "azurerm_resource_group" "rg" {
  depends_on = [terraform_data.validate]

  name     = var.azure_resource_group_name
  location = var.azure_location

  tags = local.base_tags
}

resource "azurerm_virtual_network" "vnet" {
  depends_on = [terraform_data.validate]

  name                = var.azure_vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = [module.uddi_cloud_network.vpc_cidr]

  tags = local.base_tags
}

resource "azurerm_subnet" "subnets" {
  depends_on = [terraform_data.validate]

  for_each = {
    for i in range(local.subnet_count) : tostring(i) => {
      name = local.subnet_names[i]
      cidr = local.subnet_cidrs[i]
    }
  }

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [each.value.cidr]
}

locals {
  vm_instances = var.azure_vm_enabled ? {
    for i in range(var.azure_vm_count) : tostring(i) => {
      index = i
      name  = local.vm_hostnames_effective[i]
      fqdn  = format("%s.%s", local.vm_hostnames_effective[i], local.dns_zone_fqdn_normalized)
    }
  } : {}

  vm_subnet_key = tostring(coalesce(var.azure_vm_subnet_index, module.uddi_cloud_network.host_subnet_index))

  vm_ssh_public_key_effective = (
    length(trimspace(var.azure_vm_ssh_public_key == null ? "" : var.azure_vm_ssh_public_key)) > 0
  ) ? var.azure_vm_ssh_public_key : tls_private_key.vm_ssh[0].public_key_openssh

  dns_hosts_by_fqdn = {
    for h in module.uddi_cloud_network.dns_hosts : h.fqdn => h.ip
  }
}

resource "tls_private_key" "vm_ssh" {
  count = var.azure_vm_enabled && length(trimspace(var.azure_vm_ssh_public_key == null ? "" : var.azure_vm_ssh_public_key)) == 0 ? 1 : 0

  algorithm = "ED25519"
}

resource "azurerm_public_ip" "vm_pips" {
  for_each = var.azure_vm_public_ip ? local.vm_instances : {}

  name                = format("%s-pip-%02d", var.application, each.value.index + 1)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = merge(local.base_tags, { Role = "vm" })
}

resource "azurerm_network_interface" "vm_nics" {
  for_each = local.vm_instances

  name                = format("%s-nic-%02d", var.application, each.value.index + 1)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnets[local.vm_subnet_key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.dns_hosts_by_fqdn[each.value.fqdn]
    public_ip_address_id          = var.azure_vm_public_ip ? azurerm_public_ip.vm_pips[each.key].id : null
  }

  tags = merge(local.base_tags, { Role = "vm" })
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = local.vm_instances

  name                = each.value.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size           = var.azure_vm_size
  admin_username = var.azure_vm_admin_username
  network_interface_ids = [
    azurerm_network_interface.vm_nics[each.key].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.azure_vm_admin_username
    public_key = local.vm_ssh_public_key_effective
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.azure_vm_os_disk_size_gb
  }

  tags = merge(local.base_tags, { Role = "vm" })
}
