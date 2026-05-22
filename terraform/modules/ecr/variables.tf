variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "service_names" {
  description = "List of service names for which to create ECR repositories"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Tag mutability for ECR repositories (MUTABLE for dev, IMMUTABLE for prod)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be 'MUTABLE' or 'IMMUTABLE'."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
