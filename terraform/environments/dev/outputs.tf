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

output "ecr_repository_urls" {
  description = "Map of service name to ECR repository URL"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of service name to ECR repository ARN"
  value       = module.ecr.repository_arns
}

output "rds_endpoint" {
  description = "RDS instance endpoint hostname"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

output "rds_db_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN for RDS credentials"
  value       = module.rds.secret_arn
  sensitive   = true
}

output "acm_certificate_arn" {
  description = "ACM wildcard certificate ARN"
  value       = module.dns.certificate_arn
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = module.dns.zone_id
}

output "lb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller (IRSA)"
  value       = module.dns.lb_controller_role_arn
}

output "eso_role_arn" {
  description = "IAM role ARN for the External Secrets Operator (IRSA)"
  value       = module.secrets.eso_role_arn
}

output "openai_secret_arn" {
  description = "Secrets Manager ARN for the OpenAI API key"
  value       = module.secrets.openai_secret_arn
  sensitive   = true
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — set as AWS_ROLE_ARN in GitHub Secrets"
  value       = module.github_oidc.role_arn
}
