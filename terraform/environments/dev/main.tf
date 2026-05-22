locals {
  name_prefix = "${var.project}-${var.environment}"
}

# Modules will be added here as epics are completed:
# E-2: module "vpc"
# E-3: module "eks"
# E-4: module "ecr"
# E-5: module "rds"
# E-6: module "dns"
# E-7: module "secrets"
