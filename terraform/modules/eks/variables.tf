variable "project" {
  description = "Project name"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "subnet_ids" {
  description = "Subnet IDs where the cluster and nodes will be placed"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "Security group ID for the EKS cluster control plane"
  type        = string
}

variable "node_sg_id" {
  description = "Security group ID for the EKS worker nodes"
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_ami_type" {
  description = "AMI type for worker nodes"
  type        = string
  default     = "AL2_ARM_64"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "EBS disk size in GB for each worker node"
  type        = number
  default     = 20
}

variable "node_capacity_type" {
  description = "EC2 capacity type for the node group: ON_DEMAND or SPOT. Use SPOT for dev cost savings; ON_DEMAND for prod stability."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be 'ON_DEMAND' or 'SPOT'."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "admin_principal_arn" {
  description = "IAM principal ARN (user or role) that receives cluster-admin access via EKS access entry. Set to your deploying IAM identity. Leave null to skip."
  type        = string
  default     = null
}
