variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "project" {
  description = "Project name, used as a prefix for all resource names"
  type        = string
  default     = "petclinic"
}

variable "domain_name" {
  description = "Domain name for Route 53 and ACM certificate (must already exist in Route 53)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB created by the AWS Load Balancer Controller"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (used for Route 53 alias record)"
  type        = string
  default     = ""
}

variable "alb_record_name" {
  description = "Subdomain prefix for the Route 53 alias record (e.g. petclinic-dev → petclinic-dev.diana.click)"
  type        = string
  default     = ""
}
