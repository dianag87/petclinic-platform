data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "petclinic/${var.environment}/openai-api-key"
  description             = "OpenAI API key for petclinic-${var.environment} genai-service"
  recovery_window_in_days = var.secret_recovery_window

  lifecycle {
    precondition {
      condition     = var.openai_api_key != "" || var.environment == "dev"
      error_message = "openai_api_key must be provided for prod environment."
    }
  }

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key != "" ? var.openai_api_key : "PLACEHOLDER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_iam_policy_document" "eso_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.project}-${var.environment}-eso-role"
  assume_role_policy = data.aws_iam_policy_document.eso_assume_role.json

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

data "aws_iam_policy_document" "eso_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:petclinic/${var.environment}/*",
    ]
  }
}

resource "aws_iam_policy" "eso" {
  name        = "${var.project}-${var.environment}-eso-policy"
  description = "Allow ESO to read Secrets Manager secrets under petclinic/${var.environment}/"
  policy      = data.aws_iam_policy_document.eso_policy.json

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "eso" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}
