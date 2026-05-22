output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = null
}

output "name_servers" {
  description = "Name server records for DNS delegation"
  value       = []
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = null
}
