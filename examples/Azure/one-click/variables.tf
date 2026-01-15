variable "ip_space" {
  description = "IP Space name in BloxOne (must exist)"
  type        = string
}

variable "parent_pool_cidr" {
  description = "Optional: create a parent pool (address block) if none exists for Cloud tag. Example: 10.10.0.0/16"
  type        = string
  default     = null
}

variable "size" {
  description = "T-shirt size of VNet container: small, medium, large"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "size must be one of: small, medium, large"
  }
}

variable "application" {
  description = "Name of the application using this VNet (also used for tagging)"
  type        = string
}

variable "subnet_extra_tags" {
  description = "Optional: per-subnet additional tags applied by index (count order) in BloxOne."
  type        = list(map(string))
  default     = []
}

variable "dns_zone_fqdn" {
  description = "Optional: when set, create an authoritative DNS zone in BloxOne DDI (example: azure_dns_app_zone.example.internal)."
  type        = string
  default     = null
}

variable "dns_hostnames" {
  description = "Optional: hostnames to create as A records inside dns_zone_fqdn (relative names, e.g. [\"app-01\", \"app-02\"]). If empty and dns_zone_fqdn is set, defaults to three hosts."
  type        = list(string)
  default     = []
}

variable "host_subnet_selector_tags" {
  description = "When dns_zone_fqdn is set, these tags (merged with Cloud+Application) are used to select exactly one subnet to allocate host IPs from. Example: { Role = \"dns-hosts\" }."
  type        = map(string)
  default     = {}
}

variable "azure_location" {
  description = "Azure region for the resource group and VNet (example: westus)."
  type        = string
  default     = "westus"
}

variable "azure_subscription_id" {
  description = "Optional: Azure subscription ID. If not set, the azurerm provider must be able to determine it from your auth context (e.g., env vars / Azure CLI)."
  type        = string
  default     = null
}

variable "azure_resource_group_name" {
  description = "Azure resource group name."
  type        = string
}

variable "azure_vnet_name" {
  description = "Azure VNet name."
  type        = string
}

variable "azure_subnet_names" {
  description = "Optional: Azure subnet names, in the same order as module.uddi_cloud_network.subnet_address. If empty, defaults to subnet-01..subnet-N."
  type        = list(string)
  default     = []
}

variable "azure_extra_tags" {
  description = "Optional: additional Azure tags merged with Cloud/Application."
  type        = map(string)
  default     = {}
}

variable "azure_vm_enabled" {
  description = "Optional: when true, create demo Linux VMs in Azure in one of the allocated subnets."
  type        = bool
  default     = false
}

variable "azure_vm_count" {
  description = "Number of Azure VMs to create when azure_vm_enabled is true."
  type        = number
  default     = 3
  validation {
    condition     = var.azure_vm_count >= 1 && var.azure_vm_count <= 20
    error_message = "azure_vm_count must be between 1 and 20."
  }
}

variable "azure_vm_subnet_index" {
  description = "Optional: subnet index (0-based) to place the demo VMs into. If null, defaults to the subnet selected for DNS host IP allocation (Option A)."
  type        = number
  default     = null
  validation {
    condition     = var.azure_vm_subnet_index == null ? true : (var.azure_vm_subnet_index >= 0 && var.azure_vm_subnet_index <= 3)
    error_message = "azure_vm_subnet_index must be null or between 0 and 3. (Further validation is enforced at plan/apply time based on size.)"
  }
}

variable "azure_vm_size" {
  description = "Azure VM size (SKU) for the demo VMs."
  type        = string
  default     = "Standard_B2s"
}

variable "azure_vm_admin_username" {
  description = "Admin username for the demo Linux VMs."
  type        = string
  default     = "azureuser"
}

variable "azure_vm_ssh_public_key" {
  description = "Optional: SSH public key for the demo Linux VMs (example: 'ssh-ed25519 AAAA... user@host'). If not provided, Terraform will generate a keypair (public key used for provisioning)."
  type        = string
  default     = null
}

variable "azure_vm_public_ip" {
  description = "When true, allocate a public IP for each demo VM NIC."
  type        = bool
  default     = false
}

variable "azure_vm_os_disk_size_gb" {
  description = "OS disk size (GB) for the demo VMs."
  type        = number
  default     = 30
}
