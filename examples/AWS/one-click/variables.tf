variable "ip_space" {
  description = "IP Space name in BloxOne (must exist)"
  type        = string
}

variable "parent_pool_cidr" {
  description = "Optional: create a parent pool (address block) if none exists for Cloud tag. Example: 10.0.0.0/8"
  type        = string
  default     = null
}

variable "size" {
  description = "T-shirt size of VPC container: small (2 subnets), medium or large (4 subnets)"
  type        = string
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "size must be one of: small, medium, large"
  }
}

variable "application" {
  description = "Name of the application using this VPC (also used for tagging and resource naming)"
  type        = string
}

variable "subnet_extra_tags" {
  description = "Optional: per-subnet additional tags applied by index (count order) in BloxOne."
  type        = list(map(string))
  default     = []
}

variable "dns_zone_fqdn" {
  description = "Optional: when set, create an authoritative DNS zone in BloxOne DDI (example: aws_app_zone.example.internal)."
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

variable "aws_region" {
  description = "AWS region for the VPC and instances."
  type        = string
  default     = "us-west-2"
}

variable "aws_availability_zones" {
  description = "Optional: list of AZs to assign to subnets in order. If empty, the first N available AZs in the region are used (N = subnet count)."
  type        = list(string)
  default     = []
}

variable "aws_vpc_name" {
  description = "Name tag for the AWS VPC."
  type        = string
  default     = "auto-vpc"
}

variable "aws_subnet_names" {
  description = "Optional: subnet name tags in the same order as module.uddi_cloud_network.subnet_address. If empty, defaults to subnet-01..subnet-N."
  type        = list(string)
  default     = []
}

variable "aws_extra_tags" {
  description = "Optional: additional AWS tags merged with Cloud/Application."
  type        = map(string)
  default     = {}
}

variable "aws_vm_enabled" {
  description = "Optional: when true, create demo Linux EC2 instances in one of the allocated subnets."
  type        = bool
  default     = false
}

variable "aws_vm_count" {
  description = "Number of EC2 instances to create when aws_vm_enabled is true."
  type        = number
  default     = 3
  validation {
    condition     = var.aws_vm_count >= 1 && var.aws_vm_count <= 20
    error_message = "aws_vm_count must be between 1 and 20."
  }
}

variable "aws_vm_subnet_index" {
  description = "Optional: subnet index (0-based) to place the demo instances into. If null, defaults to the subnet selected for DNS host IP allocation."
  type        = number
  default     = null
  validation {
    condition     = var.aws_vm_subnet_index == null ? true : (var.aws_vm_subnet_index >= 0 && var.aws_vm_subnet_index <= 3)
    error_message = "aws_vm_subnet_index must be null or between 0 and 3. (Further validation is enforced at plan/apply time based on size.)"
  }
}

variable "aws_vm_instance_type" {
  description = "EC2 instance type for the demo instances."
  type        = string
  default     = "t3.micro"
}

variable "aws_vm_ami_id" {
  description = "Optional: AMI ID for the demo instances. If not provided, the latest Ubuntu 22.04 LTS (amd64) AMI in the region is used."
  type        = string
  default     = null
}

variable "aws_vm_ssh_public_key" {
  description = "Optional: SSH public key for the demo instances (example: 'ssh-ed25519 AAAA... user@host'). If not provided, Terraform generates a keypair and the public key is uploaded to AWS."
  type        = string
  default     = null
}

variable "aws_vm_public_ip" {
  description = "When true, attach public IPs to the demo instances and create an Internet Gateway with a public route table."
  type        = bool
  default     = false
}

variable "aws_vm_root_volume_size_gb" {
  description = "Root EBS volume size (GB) for the demo instances."
  type        = number
  default     = 20
}
