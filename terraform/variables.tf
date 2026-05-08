variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "af-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "domain" {
  description = "Root domain used for ingress and TLS certificates"
  type        = string
  default     = "gregddevops.com.ng"
}
