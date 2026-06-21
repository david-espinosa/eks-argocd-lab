data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  aws_region         = var.aws_region
  enable_nat_gateway = var.enable_nat_gateway
}

module "eks" {
  source       = "./modules/eks"
  project_name = var.project_name
  aws_region   = var.aws_region

  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids

  cluster_version = var.cluster_version

  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_private_endpoint = true
  enable_public_endpoint = true

  enable_control_plane_logging = var.enable_control_plane_logging

  node_instance_types = var.node_instance_types
  node_min_size = var.node_min_size
  node_max_size = var.node_max_size
  node_desired_size = var.node_desired_size
}
