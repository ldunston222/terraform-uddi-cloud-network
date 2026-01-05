terraform {
  required_providers {
    bloxone = {
      source  = "infobloxopen/bloxone"
    }
    aws = {
        source = "hashicorp/aws"
    }
  }
}

provider "bloxone" {
#For provider and authentication options for Infoblox, refer to: https://registry.terraform.io/providers/infobloxopen/infoblox/latest/docs
}

provider "aws" {
#For provider and authentication options for AWS, refer to: https://registry.terraform.io/providers/hashicorp/aws/latest/docs 
  region  = "us-west-1" # Include AWS region for deployment
}

# Call the infoblox_cloud_network module with required variables
module "uddi_cloud_network" {
  source = "../../"
  cloud = "AWS"
  ip_space = "Cloud-Staging"
  size = "small"
  application = "demo-app"
}

# Use the AWS vpc module to create VPC and Subnets: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest  
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"
  name = "auto-vpc"
  cidr = module.uddi_cloud_network.vpc_cidr
  azs = ["us-west-1a", "us-west-1c"]
  public_subnets = [ join("/", [module.uddi_cloud_network.subnet_address[0], module.uddi_cloud_network.subnet_cidr]),join("/", [module.uddi_cloud_network.subnet_address[1], module.uddi_cloud_network.subnet_cidr]) ] # Enter address input for each subnet - 2 for small, 4 for medium and large
}