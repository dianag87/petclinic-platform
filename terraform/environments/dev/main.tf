locals {
  name_prefix = "${var.project}-${var.environment}"
}

module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"

  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b"]

  tags = {
    Component = "networking"
  }
}

# Modules will be added here as epics are completed:
# E-3: module "eks"
# E-4: module "ecr"
# E-5: module "rds"
# E-6: module "dns"
# E-7: module "secrets"
