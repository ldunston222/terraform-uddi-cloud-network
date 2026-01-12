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

