resource "aws_cloudwatch_log_group" "eks" {
  count             = var.enable_control_plane_logging ? 1 : 0
  name              = "/aws/eks/${var.project_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-control-plane-logs"
  }
}


resource "aws_eks_cluster" "main" {
  name     = var.project_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn


  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = var.enable_private_endpoint
    endpoint_public_access  = var.enable_public_endpoint
    public_access_cidrs     = var.allowed_cidr_blocks
  }

  enabled_cluster_log_types = var.enable_control_plane_logging ? var.control_plane_log_types : []

  depends_on = [
    aws_iam_role_policy_attachment.cluster_eks_policy,
    aws_cloudwatch_log_group.eks,
  ]

  tags = {
    Name = var.project_name
  }
}
