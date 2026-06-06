variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be 'dev' or 'prod'."
  }
}

variable "openai_api_key" {
  description = "OpenAI API key for the GenAI service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_recovery_window" {
  description = "Number of days before a deleted secret is permanently removed (0 = immediate, 7-30 for prod)"
  type        = number
  default     = 0
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for the ESO IRSA trust policy"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL (without https://) for IRSA conditions"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
