output "vpc_cidr" {
  description = "Allocated VPC CIDR from BloxOne."
  value       = module.uddi_cloud_network.vpc_cidr
}

output "subnet_cidr" {
  description = "Allocated subnet prefix length from BloxOne."
  value       = module.uddi_cloud_network.subnet_cidr
}

output "subnet_addresses" {
  description = "Allocated subnet network addresses (sorted) from BloxOne."
  value       = module.uddi_cloud_network.subnet_address
}

output "bloxone_dns_zone" {
  description = "BloxOne authoritative DNS zone details when dns_zone_fqdn is set."
  value       = module.uddi_cloud_network.dns_zone
}

output "bloxone_dns_hosts" {
  description = "BloxOne host FQDNs and allocated IPs when dns_zone_fqdn is set."
  value       = module.uddi_cloud_network.dns_hosts
}

output "aws_vpc" {
  description = "AWS VPC name, id, and CIDR."
  value = {
    name = var.aws_vpc_name
    id   = aws_vpc.vpc.id
    cidr = module.uddi_cloud_network.vpc_cidr
  }
}

output "aws_subnets" {
  description = "AWS subnet names, ids, CIDRs, and availability zones."
  value = [
    for k in sort(keys(aws_subnet.subnets)) : {
      name = aws_subnet.subnets[k].tags["Name"]
      id   = aws_subnet.subnets[k].id
      cidr = aws_subnet.subnets[k].cidr_block
      az   = aws_subnet.subnets[k].availability_zone
    }
  ]
}

output "aws_vms" {
  description = "Demo EC2 instance details when aws_vm_enabled is true."
  value = var.aws_vm_enabled ? [
    for k in sort(keys(aws_instance.vms)) : {
      name       = aws_instance.vms[k].tags["Name"]
      id         = aws_instance.vms[k].id
      private_ip = aws_instance.vms[k].private_ip
      public_ip  = var.aws_vm_public_ip ? aws_instance.vms[k].public_ip : null
      subnet_id  = aws_instance.vms[k].subnet_id
    }
  ] : []
}

output "aws_vm_private_key_pem" {
  description = "Generated SSH private key PEM (only set when aws_vm_ssh_public_key is not provided). Store this securely."
  sensitive   = true
  value       = length(tls_private_key.vm_ssh) > 0 ? tls_private_key.vm_ssh[0].private_key_openssh : null
}
