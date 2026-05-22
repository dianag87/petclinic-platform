output "vpc_id" {
  description = "VPC ID"
  value       = null
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = []
}

output "eks_cluster_sg_id" {
  description = "EKS cluster security group ID"
  value       = null
}

output "eks_node_sg_id" {
  description = "EKS node security group ID"
  value       = null
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = null
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = null
}
