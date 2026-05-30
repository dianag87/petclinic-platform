locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_caller_identity" "current" {}

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

module "eks" {
  source = "../../modules/eks"

  project     = var.project
  environment = var.environment

  subnet_ids    = module.vpc.public_subnet_ids
  cluster_sg_id = module.vpc.eks_cluster_sg_id
  node_sg_id    = module.vpc.eks_node_sg_id

  cluster_version     = "1.33"
  node_instance_types = ["t4g.small"]
  node_ami_type       = "AL2023_ARM_64"
  node_min_size       = 2
  node_max_size       = 4
  node_desired_size   = 2
  node_disk_size      = 20

  admin_principal_arn = data.aws_caller_identity.current.arn

  tags = {
    Component = "compute"
  }
}

module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment

  service_names = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "visits-service",
    "vets-service",
    "genai-service",
    "admin-server",
  ]

  image_tag_mutability = "MUTABLE"

  tags = {
    Component = "registry"
  }
}

# Modules will be added here as epics are completed:
# E-5: module "rds"
# E-6: module "dns"
# E-7: module "secrets"
