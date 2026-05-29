output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider (used for IRSA trust policies)"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC identity provider (without https:// prefix for IAM conditions)"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "node_group_name" {
  description = "Managed node group name"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_role_arn" {
  description = "IAM role ARN for the managed node group"
  value       = aws_iam_role.node.arn
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN for the EBS CSI driver (IRSA)"
  value       = aws_iam_role.ebs_csi.arn
}

output "vpc_cni_role_arn" {
  description = "IAM role ARN for the VPC CNI addon (IRSA)"
  value       = aws_iam_role.vpc_cni.arn
}

output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig for this cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.name}"
}
