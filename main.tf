terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
      version = "1.5.2"
    }
  }
}

#For provider and authentication options for Infoblox, refer to: https://registry.terraform.io/providers/infobloxopen/bloxone/latest/docs

locals {
# Determines number of subnets based on t-shirt size.
  subnet_count = var.size == "small" ? 2 : 4

#Azure and AWS reserve the first 2 addresses after the default gateway for their use, GCP does not.
  reserved_ip_count = var.cloud == "GCP" ? 0 : 2 
}

data "bloxone_ipam_ip_spaces" "cloud_space" {
  filters = {
    "name" = var.ip_space
  }
}

data "bloxone_ipam_address_blocks" "cloud_container" {
  filters = {
    space = data.bloxone_ipam_ip_spaces.cloud_space.results.*.id[0]
  }
  tag_filters = {
    "Cloud" = var.cloud
  }
}

resource "bloxone_ipam_address_block" "vpc_containter" {
  next_available_id = data.bloxone_ipam_address_blocks.cloud_container.results.*.id[0]
  cidr = var.vpc_size[var.size]
  space = data.bloxone_ipam_ip_spaces.cloud_space.results.*.id[0]
  tags = {
    "Cloud" = var.cloud
    "Application" = var.application
  }
}

resource "bloxone_ipam_subnet" "subnets" {
  count = local.subnet_count
  next_available_id = bloxone_ipam_address_block.vpc_containter.id
  cidr = var.subnet_size[var.size]
  space = data.bloxone_ipam_ip_spaces.cloud_space.results.*.id[0]
}