# Run from this folder:
#   terraform init
#   terraform plan
#   terraform apply

# BloxOne IPAM inputs
ip_space    = "aws-realm-001"
application = "ld_demo_vpc_001"
size        = "large"

# Only needed if you want Terraform to create the parent pool (common for demo environments):
parent_pool_cidr = "172.16.0.0/12"

# Optional BloxOne DNS demo
dns_zone_fqdn = "awsie-foxglove.internal"
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

# AWS inputs
aws_region   = "us-west-2"
aws_vpc_name = "Auto-VPC"

# Optional: demo EC2 instances in one of the allocated subnets
aws_vm_enabled      = true
aws_vm_count        = 3
aws_vm_subnet_index = null
aws_vm_public_ip    = false
# aws_vm_instance_type       = "t3.micro"
# aws_vm_root_volume_size_gb = 20
# aws_vm_ami_id              = "ami-0abcdef1234567890"  # optional; if omitted, latest Ubuntu 22.04 LTS is used
# aws_vm_ssh_public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... you@example"  # optional; if omitted a key is generated

# Optional: name subnets explicitly; must match allocated subnet count/order.
# aws_subnet_names = ["subnet-01", "subnet-02", "subnet-03", "subnet-04"]

# Optional: pin availability zones; must match allocated subnet count/order.
# aws_availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
