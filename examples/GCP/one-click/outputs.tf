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

output "gcp_vpc" {
  description = "GCP VPC network details."
  value = {
    name = google_compute_network.vpc.name
    id   = google_compute_network.vpc.id
    cidr = module.uddi_cloud_network.vpc_cidr
  }
}

output "gcp_subnets" {
  description = "GCP subnet names, ids, and CIDRs."
  value = [
    for k in sort(keys(google_compute_subnetwork.subnets)) : {
      name = google_compute_subnetwork.subnets[k].name
      id   = google_compute_subnetwork.subnets[k].id
      cidr = google_compute_subnetwork.subnets[k].ip_cidr_range
    }
  ]
}

output "gcp_vms" {
  description = "Demo GCE instance details when gcp_vm_enabled is true."
  value = var.gcp_vm_enabled ? [
    for k in sort(keys(google_compute_instance.vms)) : {
      name       = google_compute_instance.vms[k].name
      id         = google_compute_instance.vms[k].instance_id
      zone       = google_compute_instance.vms[k].zone
      private_ip = google_compute_instance.vms[k].network_interface[0].network_ip
      public_ip  = var.gcp_vm_public_ip ? try(google_compute_address.vm_pips[k].address, null) : null
      subnet_id  = google_compute_instance.vms[k].network_interface[0].subnetwork
    }
  ] : []
}

output "gcp_vm_private_key_pem" {
  description = "Generated SSH private key PEM (only set when gcp_vm_ssh_public_key is not provided). Store this securely."
  sensitive   = true
  value       = length(tls_private_key.vm_ssh) > 0 ? tls_private_key.vm_ssh[0].private_key_openssh : null
}
