variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "enabled" {
  description = "When true, create Azure resources"
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region for the resource group and VNet"
  type        = string
}

variable "vnet_name" {
  description = "Azure VNet name"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space CIDRs for the VNet"
  type        = list(string)
}

variable "subnet_names" {
  description = "Subnet names"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Subnet CIDR prefixes (same length/order as subnet_names)"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to RG and VNet"
  type        = map(string)
  default     = {}
}
