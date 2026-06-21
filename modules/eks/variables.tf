variable "project_name" {
  description = "Name prefix for all EKS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for control plane ENIs"
  type        = list(string)
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.36"
}

# ─── ACCESS ────────────────────────────────────────────
variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to reach the EKS public API endpoint"
  type        = list(string)
  default     = ["109.111.113.239/32"]
}

variable "enable_private_endpoint" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "enable_public_endpoint" {
  description = "Enable public API endpoint (kubectl from local)"
  type        = bool
  default     = true
}

# ─── CONTROL PLANE LOGGING ─────────────────────────────
variable "enable_control_plane_logging" {
  description = "Enable EKS control plane logs to CloudWatch"
  type        = bool
  default     = true
}

variable "control_plane_log_types" {
  description = "Which control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 1
}

# ─── NODE GROUP ────────────────────────────────────────
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

variable "node_disk_size_gb" {
  description = "Root EBS volume size for worker nodes in GB"
  type        = number
  default     = 20
}