terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = "1.5.2"
    }
  }
}

############################
# Locals / sizing
############################
locals {
  subnet_count  = var.size == "small" ? 2 : 4
  vpc_prefix    = var.vpc_size[var.size]
  subnet_prefix = var.subnet_size[var.size]
}

############################
# Look up IP Space (always safe)
############################
data "bloxone_ipam_ip_spaces" "cloud_space" {
  filters = {
    name = var.ip_space
  }
}

locals {
  cloud_space_id = try(data.bloxone_ipam_ip_spaces.cloud_space.results[0].id, null)
}

############################
# Look up parent container (ONLY if IP Space exists)
############################
data "bloxone_ipam_address_blocks" "cloud_container" {
  count = local.cloud_space_id == null ? 0 : 1

  filters = {
    space = local.cloud_space_id
  }

  tag_filters = {
    Cloud = var.cloud
  }
}

locals {
  existing_container_id = try(data.bloxone_ipam_address_blocks.cloud_container[0].results[0].id, null)
}

############################
# Optional: create a parent pool if none exists
############################
resource "bloxone_ipam_address_block" "parent_pool" {
  count = local.cloud_space_id != null && local.existing_container_id == null && var.parent_pool_cidr != null ? 1 : 0

  space   = local.cloud_space_id
  address = split("/", var.parent_pool_cidr)[0]
  cidr    = tonumber(split("/", var.parent_pool_cidr)[1])

  tags = {
    Cloud = var.cloud
    Role  = "parent-pool"
  }
}

locals {
  parent_container_id = local.existing_container_id != null ? local.existing_container_id : try(bloxone_ipam_address_block.parent_pool[0].id, null)
}

############################
# Validations (safe)
############################
resource "terraform_data" "validate" {
  input = "validate"

  lifecycle {
    precondition {
      condition     = local.cloud_space_id != null
      error_message = "No IP Space found with name '${var.ip_space}'. Name must match exactly."
    }

    precondition {
      condition     = local.parent_container_id != null
      error_message = "No parent container found in IP Space '${var.ip_space}' with tag Cloud='${var.cloud}'. Either create one manually or set var.parent_pool_cidr (example: 10.10.0.0/16)."
    }
  }
}

############################
# Allocate VPC/VNet block + subnets
############################
resource "bloxone_ipam_address_block" "vpc_container" {
  depends_on = [terraform_data.validate]

  next_available_id = local.parent_container_id
  space             = local.cloud_space_id
  cidr              = local.vpc_prefix

  tags = {
    Cloud       = var.cloud
    Application = var.application
  }
}

resource "bloxone_ipam_subnet" "subnets" {
  depends_on = [terraform_data.validate]
  count      = local.subnet_count

  next_available_id = bloxone_ipam_address_block.vpc_container.id
  space             = local.cloud_space_id
  cidr              = local.subnet_prefix

  tags = {
    Cloud       = var.cloud
    Application = var.application
  }
}

