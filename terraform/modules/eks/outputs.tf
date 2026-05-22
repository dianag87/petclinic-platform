output "cluster_name" {
  description = "EKS cluster name"
  value       = null
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = null
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = null
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC identity provider"
  value       = null
}

output "oidc_provider_url" {
  description = "URL of the OIDC identity provider"
  value       = null
}

output "node_group_name" {
  description = "Managed node group name"
  value       = null
}

output "node_role_arn" {
  description = "IAM role ARN for the node group"
  value       = null
}
