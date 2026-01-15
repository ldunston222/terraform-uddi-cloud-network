variable "ip_space" {
  description = "IP Space name in BloxOne (must exist)"
  type        = string
}

variable "parent_pool_cidr" {
  description = "Optional: create a parent pool (address block) if none exists for Cloud tag. Example: 10.10.0.0/16"
  type        = string
  default     = null
}

variable "cloud" {
  description = "Cloud provider for this VPC."
  type        = string
  validation {
    condition     = contains(["Azure", "AWS", "GCP"], var.cloud)
    error_message = "cloud must be one of: Azure, AWS, GCP"
  }
}

variable "size" {
  description = "T-shirt size of VPC: small, medium, large"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "size must be one of: small, medium, large"
  }
}

variable "application" {
  description = "Name of the application using this VPC"
  type        = string
  validation {
    condition     = length(var.application) >= 4
    error_message = "application must be 4+ characters"
  }
}

variable "vpc_size" {
  description = "Maps t-shirt size to prefix length for VPC"
  type        = map(number)
  default = {
    small  = 27
    medium = 26
    large  = 24
  }
}

variable "subnet_size" {
  description = "Maps t-shirt size to prefix length for subnets"
  type        = map(number)
  default = {
    small  = 28
    medium = 28
    large  = 26
  }
}

variable "subnet_extra_tags" {
  description = "Optional: per-subnet additional tags applied by index (count order). If provided, must be empty or have exactly the same length as the number of subnets (2 for small, 4 otherwise)."
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

variable "host_ip_start_offset" {
  description = "When dns_zone_fqdn is set, allocate host IPs starting at this offset inside the selected subnet (cidrhost index). Default is 4 to avoid common cloud-reserved addresses (e.g., Azure reserves .0-.3)."
  type        = number
  default     = 4
}

