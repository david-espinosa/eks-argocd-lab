variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Name prefix and tag for lab resources"
  type        = string
  default     = "eks-espi-lab"
}