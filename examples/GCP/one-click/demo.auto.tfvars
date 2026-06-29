# Run from this folder:
#   terraform init
#   terraform plan
#   terraform apply

# BloxOne IPAM inputs
# Must match an existing BloxOne IP Space name exactly.
# Example discovery command:
# curl -sS -H "Authorization: Token ${BLOXONE_API_KEY}" "${BLOXONE_CSP_URL%/}/api/ddi/v1/ipam/ip_space" | jq -r '.[].name'
ip_space    = "REPLACE_WITH_EXISTING_IP_SPACE_NAME"
application = "ld_demo_vpc_001"
size        = "large"

# Only needed if you want Terraform to create the parent pool (common for demo environments):
parent_pool_cidr = "172.20.0.0/16"

# Optional BloxOne DNS demo
dns_zone_fqdn = "gce-foxglove.internal"
dns_hostnames = ["vm-01", "vm-02", "vm-03"]

subnet_extra_tags = [
  { Role = "dns-hosts" },
  {},
  {},
  {},
]

host_subnet_selector_tags = {
  Role = "dns-hosts"
}

# GCP inputs
gcp_project_id   = "your-gcp-project-id"
gcp_region       = "us-east1"
gcp_zone         = "us-east1-b"
gcp_network_name = "auto-vpc"

# Optional: demo GCE instances in one of the allocated subnets
gcp_vm_enabled      = true
gcp_vm_count        = 3
gcp_vm_subnet_index = null
gcp_vm_public_ip    = false
# gcp_vm_machine_type       = "e2-medium"
# gcp_vm_image              = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
# gcp_vm_boot_disk_size_gb  = 20
# gcp_vm_admin_username     = "gcpuser"
# gcp_vm_ssh_public_key     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... you@example" # optional; if omitted a key is generated

# Optional: name subnets explicitly; must match allocated subnet count/order.
# gcp_subnet_names = ["subnet-01", "subnet-02", "subnet-03", "subnet-04"]
