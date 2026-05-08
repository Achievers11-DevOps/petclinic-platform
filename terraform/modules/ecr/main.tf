locals {
  common_tags = {
    Environment = var.environment
    Project     = "petclinic"
    ManagedBy   = "terraform"
  }

  services = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "vets-service",
    "visits-service",
    "genai-service",
    "admin-server",
  ]

  repositories = toset([for s in local.services : "petclinic-${var.environment}/${s}"])

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = each.key
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name
  policy     = local.lifecycle_policy
}
