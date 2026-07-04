variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA trust policy"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL for IRSA trust policy conditions (without https://)"
  type        = string
}

variable "node_role_arn" {
  description = "Node IAM role ARN — iam:PassRole is scoped to this ARN only"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
