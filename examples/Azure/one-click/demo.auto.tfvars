# Run from this folder:
#   terraform init
#   terraform plan
#   terraform apply

# BloxOne IPAM inputs
ip_space    = "azure_ip_space_001"
application = "ld_demo_vpc_001"
size        = "large"

# Only needed if you want Terraform to create the parent pool (common for demo environments):
parent_pool_cidr = "172.16.0.0/16"

# Optional BloxOne DNS demo
dns_zone_fqdn = "azurite-foxglove.internal"
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

# Azure inputs
azure_location            = "westus"
azure_resource_group_name = "autotest-rg"
azure_vnet_name           = "Auto-VNet"

# Optional: demo VMs in one of the allocated subnets
azure_vm_enabled      = true
azure_vm_count        = 3
azure_vm_subnet_index = null
azure_vm_public_ip    = false
# azure_vm_size           = "Standard_B2s"
# azure_vm_admin_username = "azureuser"
# azure_vm_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... you@example" # optional; if omitted a key is generated

# If the provider can't infer your subscription, set it explicitly.
azure_subscription_id = "f3c83d34-3cf7-454e-93e5-2d8f604289e3"

# Optional: name subnets explicitly; must match allocated subnet count/order.
# azure_subnet_names = ["subnet-01", "subnet-02", "subnet-03", "subnet-04"]
