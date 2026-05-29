output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_sg_id" {
  description = "EKS cluster security group ID"
  value       = module.vpc.eks_cluster_sg_id
}

output "eks_node_sg_id" {
  description = "EKS node security group ID"
  value       = module.vpc.eks_node_sg_id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = module.vpc.rds_sg_id
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = module.vpc.alb_sg_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA trust policies)"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_url" {
  description = "OIDC provider URL (for IRSA trust policies)"
  value       = module.eks.oidc_provider_url
}

output "eks_node_group_name" {
  description = "Managed node group name"
  value       = module.eks.node_group_name
}

output "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = module.eks.node_role_arn
}

output "eks_kubeconfig_command" {
  description = "Run this command to configure kubectl for this cluster"
  value       = module.eks.kubeconfig_command
}
