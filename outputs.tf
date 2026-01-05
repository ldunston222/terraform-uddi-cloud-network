output "vpc_cidr" {
    value = join("/", [bloxone_ipam_address_block.vpc_containter.address, bloxone_ipam_address_block.vpc_containter.cidr])
    description = "CIDR of new network container, used for VPC CIDR"
}

output "subnet_cidr" {
    value = var.subnet_size[var.size]
    description = "CIDR of new networks, used for subnet CIDRs"
}

output "subnet_address" {
    value = bloxone_ipam_subnet.subnets.*.address
    description = "Address blocks to use for new subnets"
}