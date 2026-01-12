output "vpc_cidr" {
  value       = "${bloxone_ipam_address_block.vpc_container.address}/${bloxone_ipam_address_block.vpc_container.cidr}"
  description = "CIDR of allocated VPC/VNet block"
}

output "subnet_cidr" {
  value       = var.subnet_size[var.size]
  description = "Prefix length of allocated subnets"
}

output "subnet_address" {
  value       = sort([for s in bloxone_ipam_subnet.subnets : s.address])
  description = "Sorted subnet network addresses"
}

