locals {
  name_prefix = "${var.project}-${var.environment}"
  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ─── Route 53 Hosted Zone (data source — must already exist) ─────────────────
# Route 53 automatically creates a hosted zone when a domain is registered.
# Creating a second zone here would put ACM validation records in the wrong zone,
# so we use a data source to look up the existing one.

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ─── ACM Certificate (public, DNS-validated) ─────────────────────────────────

resource "aws_acm_certificate" "main" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ─── LB Controller IAM Policy ────────────────────────────────────────────────

resource "aws_iam_policy" "lb_controller" {
  name        = "${local.name_prefix}-lb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller on ${local.name_prefix}"
  policy      = file("${path.module}/files/lb-controller-iam-policy.json")
  tags        = local.tags
}

# ─── LB Controller IRSA Role ─────────────────────────────────────────────────

data "aws_iam_policy_document" "lb_controller_assume_role" {
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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${local.name_prefix}-lb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

# ─── Route 53 Alias Record → ALB (PETPLAT-31) ────────────────────────────────
# Only created when alb_dns_name is provided (set after LBC creates the ALB).

resource "aws_route53_record" "alb_alias" {
  count = var.alb_dns_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.alb_record_name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
