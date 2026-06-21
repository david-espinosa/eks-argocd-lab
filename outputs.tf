output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = data.aws_region.current.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "kubeconfig_command" {
  description = "Run this after apply to configure kubectl"
  value       = module.eks.kubeconfig_command
}

output "lb_controller_role_arn" {
  value = module.eks.lb_controller_role_arn
}