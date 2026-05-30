output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Name server records for DNS delegation"
  value       = data.aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ACM certificate ARN (wildcard, validated)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "lb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller (IRSA)"
  value       = aws_iam_role.lb_controller.arn
}
