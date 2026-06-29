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
  description = "T-shirt size of VPC container: small, medium, large"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "size must be one of: small, medium, large"
  }
}

variable "application" {
  description = "Name of the application using this VPC (also used for tags and resource naming)"
  type        = string
}

variable "subnet_extra_tags" {
  description = "Optional: per-subnet additional tags applied by index (count order) in BloxOne."
  type        = list(map(string))
  default     = []
}

variable "dns_zone_fqdn" {
  description = "Optional: when set, create an authoritative DNS zone in BloxOne DDI (example: gcp_app_zone.example.internal)."
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

variable "gcp_project_id" {
  description = "GCP project ID where resources will be created."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for subnets and regional resources (example: us-east1)."
  type        = string
  default     = "us-east1"
}

variable "gcp_zone" {
  description = "GCP zone for demo VM instances (example: us-east1-b)."
  type        = string
  default     = "us-east1-b"
}

variable "gcp_network_name" {
  description = "Name for the GCP VPC network."
  type        = string
  default     = "auto-vpc"
}

variable "gcp_subnet_names" {
  description = "Optional: GCP subnet names in the same order as module.uddi_cloud_network.subnet_address. If empty, defaults to subnet-01..subnet-N."
  type        = list(string)
  default     = []
}

variable "gcp_extra_network_tags" {
  description = "Optional: additional network tags to apply to demo VM instances."
  type        = list(string)
  default     = []
}

variable "gcp_vm_enabled" {
  description = "Optional: when true, create demo Linux GCE instances in one of the allocated subnets."
  type        = bool
  default     = false
}

variable "gcp_vm_count" {
  description = "Number of GCE instances to create when gcp_vm_enabled is true."
  type        = number
  default     = 3
  validation {
    condition     = var.gcp_vm_count >= 1 && var.gcp_vm_count <= 20
    error_message = "gcp_vm_count must be between 1 and 20."
  }
}

variable "gcp_vm_subnet_index" {
  description = "Optional: subnet index (0-based) to place demo instances into. If null, defaults to the subnet selected for DNS host IP allocation."
  type        = number
  default     = null
  validation {
    condition     = var.gcp_vm_subnet_index == null ? true : (var.gcp_vm_subnet_index >= 0 && var.gcp_vm_subnet_index <= 3)
    error_message = "gcp_vm_subnet_index must be null or between 0 and 3. (Further validation is enforced at plan/apply time based on size.)"
  }
}

variable "gcp_vm_machine_type" {
  description = "Machine type for demo GCE instances."
  type        = string
  default     = "e2-medium"
}

variable "gcp_vm_image" {
  description = "Boot image for demo GCE instances."
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
}

variable "gcp_vm_boot_disk_size_gb" {
  description = "Boot disk size (GB) for demo GCE instances."
  type        = number
  default     = 20
}

variable "gcp_vm_admin_username" {
  description = "Linux username for SSH key metadata on demo instances."
  type        = string
  default     = "gcpuser"
}

variable "gcp_vm_ssh_public_key" {
  description = "Optional: SSH public key for demo GCE instances (example: 'ssh-ed25519 AAAA... user@host'). If not provided, Terraform generates a keypair."
  type        = string
  default     = null
}

variable "gcp_vm_public_ip" {
  description = "When true, allocate static public IPs and attach them to demo instances."
  type        = bool
  default     = false
}
