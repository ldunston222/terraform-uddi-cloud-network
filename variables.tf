variable "ip_space" {
  description = "IP Space in BloxOne to search for and create resources"
  type = string
  default = "default"
}

variable "cloud" {
  description = "Cloud provider for this VPC."
  type = string
  validation {
    condition = contains(["Azure", "AWS", "GCP"], var.cloud)
    error_message = "The value of cloud must be one of the following: Azure, AWS, or GCP"
  }
}

variable "size" {
  description = "T-shirt size of VPC: small, medium, large"
  type = string
  validation {
    condition = contains(["small", "medium", "large"], var.size)
    error_message = "The value of size must be one of the following: small, medium, or large"
  }
}

variable "application" {
  description = "Name of the application using this VPC"
  type = string
    validation {
    condition = length(var.application) >= 4
    error_message = "You must enter a name for the application, 4 or more characters"
  }
}

variable "vpc_size" {
  description = "Maps t-shirt size to prefix length for VPC"
  type = map(number)
  default = {
    small = 27
    medium = 26
    large = 24
  }
}

variable "subnet_size" {
  description = "Maps t-shirt size to prefix length for subnets"
  type = map(number)
  default = {
    small = 28
    medium = 28
    large = 26
  }
}