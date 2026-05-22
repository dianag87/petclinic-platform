output "endpoint" {
  description = "RDS instance endpoint hostname"
  value       = null
}

output "port" {
  description = "RDS port"
  value       = 3306
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = null
}

output "secret_arn" {
  description = "Secrets Manager secret ARN for RDS credentials"
  value       = null
  sensitive   = true
}
