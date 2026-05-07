locals {
  common_tags = {
    Environment = var.environment
    Project     = "petclinic"
    ManagedBy   = "terraform"
  }
}

# ── Random Password ───────────────────────────────────────────────────────────

resource "random_password" "db" {
  length  = 16
  special = false
}

# ── Subnet Group ──────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "this" {
  name       = "petclinic-${var.environment}-rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "petclinic-${var.environment}-rds-subnet-group"
  })
}

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "petclinic-${var.environment}-rds-sg"
  description = "Allow MySQL from VPC CIDR and EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from VPC CIDR"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "MySQL from EKS node security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "petclinic-${var.environment}-rds-sg"
  })
}

# ── RDS Instance ──────────────────────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier             = "petclinic-${var.environment}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "petclinic"
  username               = "petclinic"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = merge(local.common_tags, {
    Name = "petclinic-${var.environment}-mysql"
  })
}

# ── Secrets Manager ───────────────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "petclinic/${var.environment}/db-credentials"
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = aws_db_instance.this.username
    password = random_password.db.result
    endpoint = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = aws_db_instance.this.db_name
  })
}
