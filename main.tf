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

  base_tags = {
    Cloud       = var.cloud
    Application = var.application
  }

  dns_zone_fqdn_normalized = var.dns_zone_fqdn == null ? null : trimsuffix(var.dns_zone_fqdn, ".")
  dns_zone_fqdn_provider   = local.dns_zone_fqdn_normalized == null ? null : "${local.dns_zone_fqdn_normalized}."
  dns_hostnames_effective  = var.dns_zone_fqdn == null ? [] : (length(var.dns_hostnames) > 0 ? var.dns_hostnames : ["app-01", "app-02", "app-03"])
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
    Role  = "parent-pool"
  }
}

locals {
  discovered_parent_container_id = try(data.bloxone_ipam_address_blocks.cloud_container[0].results[0].id, null)
  existing_container_id          = var.parent_pool_cidr != null ? null : local.discovered_parent_container_id

  subnet_tags_by_index = [
    for i in range(local.subnet_count) : merge(
      local.base_tags,
      try(var.subnet_extra_tags[i], {})
    )
  ]

  required_host_subnet_tags = merge(local.base_tags, var.host_subnet_selector_tags)
  host_subnet_indices = [
    for i in range(local.subnet_count) : i
    if alltrue([
      for k, v in local.required_host_subnet_tags : lookup(local.subnet_tags_by_index[i], k, null) == v
    ])
  ]

  host_subnet_match_count = length(local.host_subnet_indices)
  host_subnet_index       = try(local.host_subnet_indices[0], null)
  host_subnet_id          = var.dns_zone_fqdn == null ? null : try(bloxone_ipam_subnet.subnets[local.host_subnet_index].id, null)

  host_subnet_cidr = var.dns_zone_fqdn == null ? null : "${try(bloxone_ipam_subnet.subnets[local.host_subnet_index].address, "0.0.0.0")}/${local.subnet_prefix}"
  dns_host_ips = var.dns_zone_fqdn == null ? [] : [
    for i in range(length(local.dns_hostnames_effective)) : cidrhost(local.host_subnet_cidr, var.host_ip_start_offset + i)
  ]
}

############################
# Optional: create a parent pool if none exists
############################
resource "bloxone_ipam_address_block" "parent_pool" {
  count = local.cloud_space_id != null && var.parent_pool_cidr != null ? 1 : 0

  space   = local.cloud_space_id
  address = split("/", var.parent_pool_cidr)[0]
  cidr    = tonumber(split("/", var.parent_pool_cidr)[1])

  tags = {
    Cloud = var.cloud
    Role  = "parent-pool"
  }
}

locals {
  parent_container_id = var.parent_pool_cidr != null ? try(bloxone_ipam_address_block.parent_pool[0].id, null) : local.discovered_parent_container_id
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

    precondition {
      condition     = length(var.subnet_extra_tags) == 0 || length(var.subnet_extra_tags) == local.subnet_count
      error_message = "If subnet_extra_tags is set, it must be empty or have exactly ${local.subnet_count} elements (one per subnet)."
    }

    precondition {
      condition     = var.dns_zone_fqdn == null || length(var.host_subnet_selector_tags) > 0
      error_message = "When dns_zone_fqdn is set, host_subnet_selector_tags must be non-empty so exactly one subnet can be selected."
    }

    precondition {
      condition     = var.dns_zone_fqdn == null || local.host_subnet_match_count == 1
      error_message = "When dns_zone_fqdn is set, host_subnet_selector_tags must match exactly one subnet. Matched ${local.host_subnet_match_count}."
    }

    precondition {
      condition     = var.dns_zone_fqdn == null || var.host_ip_start_offset >= 1
      error_message = "When dns_zone_fqdn is set, host_ip_start_offset must be >= 1 (cidrhost index)."
    }

    precondition {
      condition = var.dns_zone_fqdn == null || (
        (var.host_ip_start_offset + length(local.dns_hostnames_effective) - 1) < pow(2, 32 - local.subnet_prefix)
      )
      error_message = "When dns_zone_fqdn is set, host_ip_start_offset (${var.host_ip_start_offset}) is too large for subnet prefix /${local.subnet_prefix} with ${length(local.dns_hostnames_effective)} hosts."
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

  tags = local.base_tags
}

resource "bloxone_ipam_subnet" "subnets" {
  depends_on = [terraform_data.validate]
  count      = local.subnet_count

  next_available_id = bloxone_ipam_address_block.vpc_container.id
  space             = local.cloud_space_id
  cidr              = local.subnet_prefix

  tags = merge(local.base_tags, try(var.subnet_extra_tags[count.index], {}))
}

############################
# Optional: DNS zone + hosts
############################
resource "bloxone_dns_auth_zone" "app_zone" {
  depends_on = [terraform_data.validate]
  count      = var.dns_zone_fqdn == null ? 0 : 1

  fqdn         = local.dns_zone_fqdn_provider
  primary_type = "cloud"

  tags = merge(local.base_tags, {
    Role = "app-zone"
  })
}

resource "bloxone_ipam_host" "dns_hosts" {
  depends_on = [terraform_data.validate]
  count      = var.dns_zone_fqdn == null ? 0 : length(local.dns_hostnames_effective)

  name = "${local.dns_hostnames_effective[count.index]}.${local.dns_zone_fqdn_normalized}"

  addresses = [
    {
      address = local.dns_host_ips[count.index]
      space   = local.cloud_space_id
    }
  ]

  tags = merge(local.base_tags, {
    Role = "dns-host"
  })
}

resource "bloxone_dns_a_record" "dns_hosts" {
  depends_on = [terraform_data.validate]
  count      = var.dns_zone_fqdn == null ? 0 : length(local.dns_hostnames_effective)

  zone         = bloxone_dns_auth_zone.app_zone[0].id
  name_in_zone = local.dns_hostnames_effective[count.index]

  rdata = {
    address = bloxone_ipam_host.dns_hosts[count.index].addresses[0].address
  }

  tags = merge(local.base_tags, {
    Role = "dns-a"
  })
}

