output "vpc_cidr" {
  description = "CIDR of allocated VPC/VNet block."
  value       = "${bloxone_ipam_address_block.vpc_container.address}/${bloxone_ipam_address_block.vpc_container.cidr}"
}

output "subnet_cidr" {
  description = "Prefix length of allocated subnets."
  value       = var.subnet_size[var.size]
}

output "subnet_address" {
  description = "Subnet network addresses (sorted)."
  value       = sort([for s in bloxone_ipam_subnet.subnets : s.address])
}

output "subnets" {
  description = "Subnets in count order with ids and tags."
  value = [
    for s in bloxone_ipam_subnet.subnets : {
      id      = s.id
      address = s.address
      cidr    = s.cidr
      tags    = s.tags
    }
  ]
}

output "dns_zone" {
  description = "DNS zone details when dns_zone_fqdn is set."
  value = var.dns_zone_fqdn == null ? null : {
    id   = bloxone_dns_auth_zone.app_zone[0].id
    fqdn = bloxone_dns_auth_zone.app_zone[0].fqdn
  }
}

output "dns_hosts" {
  description = "Host FQDNs and allocated IPs when dns_zone_fqdn is set."
  value = var.dns_zone_fqdn == null ? [] : [
    for h in bloxone_ipam_host.dns_hosts : {
      fqdn = h.name
      ip   = h.addresses[0].address
    }
  ]
}

output "host_subnet_index" {
  description = "0-based subnet index selected for allocating DNS host IPs when dns_zone_fqdn is set."
  value       = var.dns_zone_fqdn == null ? null : local.host_subnet_index
}

output "host_subnet_cidr" {
  description = "Selected subnet CIDR (address/prefix) used for allocating DNS host IPs when dns_zone_fqdn is set."
  value       = var.dns_zone_fqdn == null ? null : local.host_subnet_cidr
}

