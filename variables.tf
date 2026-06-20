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

variable "enable_nat_gateway" {
  description = "Create NAT Gateway for private node egress. Costs ~$0.045/hr when enabled."
  type        = bool
  default     = true
}
