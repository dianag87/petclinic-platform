variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the Route 53 hosted zone (must already exist in Route 53)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider (for LB controller IRSA trust policy)"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider without https:// prefix (for IAM conditions)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB created by the Load Balancer Controller"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (for Route 53 alias record)"
  type        = string
  default     = ""
}

variable "alb_record_name" {
  description = "Subdomain prefix for the Route 53 alias record (e.g. petclinic-dev)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
