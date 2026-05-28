locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ── VPC ────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# ── Public subnets ─────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                         = "${local.name_prefix}-public-${count.index + 1}"
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  })
}

# ── Internet Gateway ───────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# ── Route table: 0.0.0.0/0 → IGW ──────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── EKS Cluster Security Group ─────────────────────────────────────────────────
# Controls access to the Kubernetes API server.

resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-cluster-sg"
  description = "EKS cluster control plane security group"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  security_group_id        = aws_security_group.eks_cluster.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = aws_security_group.eks_node.id
  description              = "API server access from worker nodes"
}

resource "aws_security_group_rule" "cluster_egress_all" {
  security_group_id = aws_security_group.eks_cluster.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}

# ── EKS Node Security Group ────────────────────────────────────────────────────
# Governs worker node access. SGs are the perimeter in this all-public design.

resource "aws_security_group" "eks_node" {
  name        = "${local.name_prefix}-node-sg"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-node-sg"
  })
}

resource "aws_security_group_rule" "node_ingress_from_cluster" {
  security_group_id        = aws_security_group.eks_node.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "All traffic from cluster control plane"
}

resource "aws_security_group_rule" "node_ingress_self" {
  security_group_id = aws_security_group.eks_node.id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  self              = true
  description       = "Inter-node communication"
}

resource "aws_security_group_rule" "node_ingress_kubelet" {
  security_group_id        = aws_security_group.eks_node.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Kubelet API from cluster control plane"
}

resource "aws_security_group_rule" "node_ingress_nodeport_from_alb" {
  security_group_id        = aws_security_group.eks_node.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 30000
  to_port                  = 32767
  source_security_group_id = aws_security_group.alb.id
  description              = "NodePort services from ALB"
}

resource "aws_security_group_rule" "node_egress_all" {
  security_group_id = aws_security_group.eks_node.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}

# ── RDS Security Group ─────────────────────────────────────────────────────────
# MySQL 3306 from EKS nodes ONLY — never 0.0.0.0/0.

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS MySQL security group - access from EKS nodes only"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}

resource "aws_security_group_rule" "rds_ingress_mysql_from_nodes" {
  security_group_id        = aws_security_group.rds.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.eks_node.id
  description              = "MySQL from EKS nodes only"
}

# ── ALB Security Group ─────────────────────────────────────────────────────────
# Internet-facing load balancer: HTTP/HTTPS inbound, NodePort range outbound.

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB security group - HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP from internet"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS from internet"
}

resource "aws_security_group_rule" "alb_egress_nodeport" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 30000
  to_port                  = 32767
  source_security_group_id = aws_security_group.eks_node.id
  description              = "To node ports on EKS nodes"
}

resource "aws_security_group_rule" "alb_egress_health_check" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.eks_node.id
  description              = "Health checks to API Gateway on nodes"
}
