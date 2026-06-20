data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  aws_region         = var.aws_region
  enable_nat_gateway = var.enable_nat_gateway
}