output "openai_secret_arn" {
  description = "Secrets Manager ARN for the OpenAI API key"
  value       = aws_secretsmanager_secret.openai_api_key.arn
  sensitive   = true
}

output "eso_role_arn" {
  description = "IAM role ARN for the External Secrets Operator (IRSA)"
  value       = aws_iam_role.eso.arn
}
