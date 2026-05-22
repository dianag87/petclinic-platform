variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key for the GenAI service"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
