variable "app_repo" {
  description = "GitHub repo that will assume the role, in org/repo format (e.g. dianag87/spring-petclinic-microservices)"
  type        = string
}

variable "project" {
  description = "Project name, used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
