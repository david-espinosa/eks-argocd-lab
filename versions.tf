terraform {
  required_version = ">= 1.15.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "eks-espi-lab-tfstate"
    key = "eks-espi-lab/terraform.tfstate"
    region = "eu-north-1"
    use_lockfile = "true"
  }
}