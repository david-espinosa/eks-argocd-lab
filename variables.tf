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
  default     = false
}

# EKS
variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to reach the EKS public API endpoint"
  type        = list(string)
  default     = ["109.111.113.239/32"]
}

variable "enable_control_plane_logging" {
  description = "Enable EKS control plane logs to CloudWatch"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EC2 Spot instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_desired_size" {
  type    = number
  default = 2
}