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

# ─── Random Password ─────────────────────────────────────────────────────────
# Excludes characters that break MySQL connection strings or shell quoting.

resource "random_password" "master" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

# ─── Secrets Manager (PETPLAT-23) ────────────────────────────────────────────

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "petclinic/${var.environment}/rds-credentials"
  description = "RDS master credentials for ${local.name_prefix}"
  # 0 = immediate deletion; allows terraform destroy + re-apply without a 7-30 day recovery wait
  recovery_window_in_days = 0
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "petclinic"
    password = random_password.master.result
  })
}

# ─── DB Subnet Group ─────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "DB subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids
  tags        = local.tags
}

# ─── Parameter Group ─────────────────────────────────────────────────────────

resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-mysql8"
  family      = "mysql8.0"
  description = "MySQL 8.0 parameter group for ${local.name_prefix}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = local.tags
}

# ─── RDS Instance ─────────────────────────────────────────────────────────────

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "petclinic"
  username = "petclinic"
  password = random_password.master.result

  multi_az               = var.multi_az
  publicly_accessible    = false
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = var.skip_final_snapshot
  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = true

  tags = local.tags

  # Ignore password changes after creation so out-of-band rotations aren't reverted
  lifecycle {
    ignore_changes = [password]
  }

  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
}
