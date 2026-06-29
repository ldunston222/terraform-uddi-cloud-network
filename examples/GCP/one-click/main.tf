terraform {
  required_version = ">= 1.4.0"

  required_providers {
    bloxone = {
      source = "infobloxopen/bloxone"
    }
    google = {
      source = "hashicorp/google"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

provider "bloxone" {
  # For provider and authentication options for Infoblox, refer to:
  # https://registry.terraform.io/providers/infobloxopen/bloxone/latest/docs
}

provider "google" {
  # For provider and authentication options for GCP, refer to:
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

locals {
  subnet_count = var.size == "small" ? 2 : 4

  base_tags = concat(["cloud-gcp", format("app-%s", var.application)], var.gcp_extra_network_tags)

  subnet_names = length(var.gcp_subnet_names) > 0 ? var.gcp_subnet_names : [
    for i in range(local.subnet_count) : format("subnet-%02d", i + 1)
  ]

  subnet_cidrs = [
    for i in range(local.subnet_count) : join("/", [module.uddi_cloud_network.subnets[i].address, tostring(module.uddi_cloud_network.subnets[i].cidr)])
  ]

  dns_zone_fqdn_normalized = var.dns_zone_fqdn == null ? null : trimsuffix(var.dns_zone_fqdn, ".")

  vm_hostnames_effective = var.dns_zone_fqdn == null ? [] : (
    length(var.dns_hostnames) > 0 ? var.dns_hostnames : ["app-01", "app-02", "app-03"]
  )
}

module "uddi_cloud_network" {
  source = "../../../"

  ip_space         = var.ip_space
  parent_pool_cidr = var.parent_pool_cidr

  cloud       = "GCP"
  size        = var.size
  application = var.application

  subnet_extra_tags         = var.subnet_extra_tags
  dns_zone_fqdn             = var.dns_zone_fqdn
  dns_hostnames             = var.dns_hostnames
  host_subnet_selector_tags = var.host_subnet_selector_tags
}

resource "terraform_data" "validate" {
  input = "validate"

  lifecycle {
    precondition {
      condition     = length(var.gcp_subnet_names) == 0 || length(var.gcp_subnet_names) == local.subnet_count
      error_message = "If gcp_subnet_names is set, it must be empty or have exactly ${local.subnet_count} elements (one per subnet)."
    }

    precondition {
      condition = var.gcp_vm_enabled == false || (
        coalesce(var.gcp_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) != null &&
        coalesce(var.gcp_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) >= 0 &&
        coalesce(var.gcp_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) < local.subnet_count
      )
      error_message = "When gcp_vm_enabled is true, the effective VM subnet index must be in range 0..${local.subnet_count - 1} for size='${var.size}'. Set gcp_vm_subnet_index explicitly or ensure host_subnet_selector_tags selects a valid subnet."
    }

    precondition {
      condition     = var.gcp_vm_enabled == false || var.dns_zone_fqdn != null
      error_message = "When gcp_vm_enabled is true, dns_zone_fqdn must be set so VM IPs can be allocated in BloxOne and published in DNS."
    }

    precondition {
      condition     = var.gcp_vm_enabled == false || var.gcp_vm_count == length(local.vm_hostnames_effective)
      error_message = "When gcp_vm_enabled is true, gcp_vm_count must equal the number of effective dns_hostnames (${length(local.vm_hostnames_effective)})."
    }
  }
}

resource "google_compute_network" "vpc" {
  depends_on = [terraform_data.validate]

  name                    = var.gcp_network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnets" {
  depends_on = [terraform_data.validate]

  for_each = {
    for i in range(local.subnet_count) : tostring(i) => {
      name = local.subnet_names[i]
      cidr = local.subnet_cidrs[i]
    }
  }

  name          = each.value.name
  ip_cidr_range = each.value.cidr
  network       = google_compute_network.vpc.id
  region        = var.gcp_region
}

locals {
  vm_instances = var.gcp_vm_enabled ? {
    for i in range(var.gcp_vm_count) : tostring(i) => {
      index = i
      name  = local.vm_hostnames_effective[i]
      fqdn  = format("%s.%s", local.vm_hostnames_effective[i], local.dns_zone_fqdn_normalized)
    }
  } : {}

  vm_subnet_key = tostring(coalesce(var.gcp_vm_subnet_index, module.uddi_cloud_network.host_subnet_index))

  vm_ssh_public_key_effective = (
    length(trimspace(var.gcp_vm_ssh_public_key == null ? "" : var.gcp_vm_ssh_public_key)) > 0
  ) ? var.gcp_vm_ssh_public_key : tls_private_key.vm_ssh[0].public_key_openssh

  dns_hosts_by_fqdn = {
    for h in module.uddi_cloud_network.dns_hosts : h.fqdn => h.ip
  }
}

resource "tls_private_key" "vm_ssh" {
  count = var.gcp_vm_enabled && length(trimspace(var.gcp_vm_ssh_public_key == null ? "" : var.gcp_vm_ssh_public_key)) == 0 ? 1 : 0

  algorithm = "ED25519"
}

resource "google_compute_firewall" "vm_ssh" {
  count = var.gcp_vm_enabled && var.gcp_vm_public_ip ? 1 : 0

  name    = format("%s-allow-ssh", var.application)
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_address" "vm_pips" {
  for_each = var.gcp_vm_public_ip ? local.vm_instances : {}

  name   = format("%s-ip-%02d", var.application, each.value.index + 1)
  region = var.gcp_region
}

resource "google_compute_instance" "vms" {
  for_each = local.vm_instances

  name         = each.value.name
  machine_type = var.gcp_vm_machine_type
  zone         = var.gcp_zone

  tags = var.gcp_vm_public_ip ? concat(local.base_tags, ["ssh"]) : local.base_tags

  boot_disk {
    initialize_params {
      image = var.gcp_vm_image
      size  = var.gcp_vm_boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets[local.vm_subnet_key].id
    network_ip = local.dns_hosts_by_fqdn[each.value.fqdn]

    dynamic "access_config" {
      for_each = var.gcp_vm_public_ip ? [1] : []
      content {
        nat_ip = google_compute_address.vm_pips[each.key].address
      }
    }
  }

  metadata = {
    ssh-keys = format("%s:%s", var.gcp_vm_admin_username, local.vm_ssh_public_key_effective)
  }
}
