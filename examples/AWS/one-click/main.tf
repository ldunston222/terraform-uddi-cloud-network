terraform {
  required_version = ">= 1.4.0"

  required_providers {
    bloxone = {
      source = "infobloxopen/bloxone"
    }
    aws = {
      source = "hashicorp/aws"
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

provider "aws" {
  # For provider and authentication options for AWS, refer to:
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  count = var.aws_vm_enabled ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  subnet_count = var.size == "small" ? 2 : 4

  effective_azs = length(var.aws_availability_zones) > 0 ? var.aws_availability_zones : slice(data.aws_availability_zones.available.names, 0, local.subnet_count)

  subnet_names = length(var.aws_subnet_names) > 0 ? var.aws_subnet_names : [
    for i in range(local.subnet_count) : format("subnet-%02d", i + 1)
  ]

  subnet_cidrs = [
    for i in range(local.subnet_count) : join("/", [module.uddi_cloud_network.subnets[i].address, tostring(module.uddi_cloud_network.subnets[i].cidr)])
  ]

  base_tags = merge(
    {
      Cloud       = "AWS"
      Application = var.application
    },
    var.aws_extra_tags
  )

  dns_zone_fqdn_normalized = var.dns_zone_fqdn == null ? null : trimsuffix(var.dns_zone_fqdn, ".")

  vm_hostnames_effective = var.dns_zone_fqdn == null ? [] : (
    length(var.dns_hostnames) > 0 ? var.dns_hostnames : ["app-01", "app-02", "app-03"]
  )

  vm_instances = var.aws_vm_enabled ? {
    for i in range(var.aws_vm_count) : tostring(i) => {
      index = i
      name  = local.vm_hostnames_effective[i]
      fqdn  = format("%s.%s", local.vm_hostnames_effective[i], local.dns_zone_fqdn_normalized)
    }
  } : {}

  vm_subnet_key = tostring(coalesce(var.aws_vm_subnet_index, module.uddi_cloud_network.host_subnet_index))

  vm_ssh_public_key_effective = (
    length(trimspace(var.aws_vm_ssh_public_key == null ? "" : var.aws_vm_ssh_public_key)) > 0
  ) ? var.aws_vm_ssh_public_key : tls_private_key.vm_ssh[0].public_key_openssh

  dns_hosts_by_fqdn = {
    for h in module.uddi_cloud_network.dns_hosts : h.fqdn => h.ip
  }

  vm_ami_id_effective = coalesce(var.aws_vm_ami_id, try(data.aws_ami.ubuntu[0].id, null))
}

# ---------------------------------------------------------------------------
# BloxOne IPAM module
# ---------------------------------------------------------------------------

module "uddi_cloud_network" {
  source = "../../../"

  ip_space         = var.ip_space
  parent_pool_cidr = var.parent_pool_cidr

  cloud       = "AWS"
  size        = var.size
  application = var.application

  subnet_extra_tags         = var.subnet_extra_tags
  dns_zone_fqdn             = var.dns_zone_fqdn
  dns_hostnames             = var.dns_hostnames
  host_subnet_selector_tags = var.host_subnet_selector_tags
}

# ---------------------------------------------------------------------------
# Precondition validation
# ---------------------------------------------------------------------------

resource "terraform_data" "validate" {
  input = "validate"

  lifecycle {
    precondition {
      condition     = length(var.aws_availability_zones) == 0 || length(var.aws_availability_zones) == local.subnet_count
      error_message = "If aws_availability_zones is set, it must be empty or have exactly ${local.subnet_count} elements (one per subnet)."
    }

    precondition {
      condition     = length(var.aws_subnet_names) == 0 || length(var.aws_subnet_names) == local.subnet_count
      error_message = "If aws_subnet_names is set, it must be empty or have exactly ${local.subnet_count} elements (one per subnet)."
    }

    precondition {
      condition = var.aws_vm_enabled == false || (
        coalesce(var.aws_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) != null &&
        coalesce(var.aws_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) >= 0 &&
        coalesce(var.aws_vm_subnet_index, module.uddi_cloud_network.host_subnet_index) < local.subnet_count
      )
      error_message = "When aws_vm_enabled is true, the effective VM subnet index must be in range 0..${local.subnet_count - 1} for size='${var.size}'. Set aws_vm_subnet_index explicitly or ensure host_subnet_selector_tags selects a valid subnet."
    }

    precondition {
      condition     = var.aws_vm_enabled == false || var.dns_zone_fqdn != null
      error_message = "When aws_vm_enabled is true, dns_zone_fqdn must be set so VM IPs can be allocated in BloxOne and published in DNS."
    }

    precondition {
      condition     = var.aws_vm_enabled == false || var.aws_vm_count == length(local.vm_hostnames_effective)
      error_message = "When aws_vm_enabled is true, aws_vm_count must equal the number of effective dns_hostnames (${length(local.vm_hostnames_effective)})."
    }
  }
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  depends_on = [terraform_data.validate]

  cidr_block           = module.uddi_cloud_network.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.base_tags, { Name = var.aws_vpc_name })
}

resource "aws_subnet" "subnets" {
  depends_on = [terraform_data.validate]

  for_each = {
    for i in range(local.subnet_count) : tostring(i) => {
      name = local.subnet_names[i]
      cidr = local.subnet_cidrs[i]
      az   = local.effective_azs[i]
    }
  }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.base_tags, { Name = each.value.name })
}

# ---------------------------------------------------------------------------
# Internet gateway + public routing (only when aws_vm_public_ip is true)
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  count = var.aws_vm_public_ip ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(local.base_tags, { Name = format("%s-igw", var.aws_vpc_name) })
}

resource "aws_route_table" "public" {
  count = var.aws_vm_public_ip ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(local.base_tags, { Name = format("%s-rt-public", var.aws_vpc_name) })
}

resource "aws_route_table_association" "public" {
  for_each = var.aws_vm_public_ip ? {
    for i in range(local.subnet_count) : tostring(i) => aws_subnet.subnets[tostring(i)].id
  } : {}

  subnet_id      = each.value
  route_table_id = aws_route_table.public[0].id
}

# ---------------------------------------------------------------------------
# SSH key pair
# ---------------------------------------------------------------------------

resource "tls_private_key" "vm_ssh" {
  count = var.aws_vm_enabled && length(trimspace(var.aws_vm_ssh_public_key == null ? "" : var.aws_vm_ssh_public_key)) == 0 ? 1 : 0

  algorithm = "ED25519"
}

resource "aws_key_pair" "vm_key" {
  count = var.aws_vm_enabled ? 1 : 0

  key_name   = format("%s-vm-key", var.application)
  public_key = local.vm_ssh_public_key_effective

  tags = local.base_tags
}

# ---------------------------------------------------------------------------
# Security group
# ---------------------------------------------------------------------------

resource "aws_security_group" "vm_sg" {
  count = var.aws_vm_enabled ? 1 : 0

  name        = format("%s-vm-sg", var.application)
  description = "Demo security group for ${var.application} VMs"
  vpc_id      = aws_vpc.vpc.id

  # Tighten source CIDRs for production; this is intentionally open for demo use.
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, { Name = format("%s-vm-sg", var.application), Role = "vm" })
}

# ---------------------------------------------------------------------------
# EC2 instances
# ---------------------------------------------------------------------------

resource "aws_instance" "vms" {
  for_each = local.vm_instances

  ami           = local.vm_ami_id_effective
  instance_type = var.aws_vm_instance_type
  subnet_id     = aws_subnet.subnets[local.vm_subnet_key].id
  private_ip    = local.dns_hosts_by_fqdn[each.value.fqdn]
  key_name      = aws_key_pair.vm_key[0].key_name

  vpc_security_group_ids      = [aws_security_group.vm_sg[0].id]
  associate_public_ip_address = var.aws_vm_public_ip

  root_block_device {
    volume_size = var.aws_vm_root_volume_size_gb
    volume_type = "gp3"
  }

  tags = merge(local.base_tags, { Name = each.value.name, Role = "vm" })
}
