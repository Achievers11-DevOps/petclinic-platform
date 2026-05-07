terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "petclinic"
      ManagedBy   = "terraform"
    }
  }
}

# ── VPC ──────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  cluster_name = var.cluster_name
  environment  = var.environment
}

# ── EKS ──────────────────────────────────────────────────────────────────────

module "eks" {
  source = "./modules/eks"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids

  depends_on = [module.vpc]
}

# ── RDS ──────────────────────────────────────────────────────────────────────

module "rds" {
  source = "./modules/rds"

  cluster_name           = var.cluster_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr               = module.vpc.vpc_cidr
  subnet_ids             = module.vpc.public_subnet_ids
  node_security_group_id = module.eks.node_security_group_id

  depends_on = [module.vpc, module.eks]
}

# ── ECR ──────────────────────────────────────────────────────────────────────

module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
}

