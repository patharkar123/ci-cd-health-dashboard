# Variables for CI/CD Dashboard Infrastructure
# Generated with AI assistance (Cursor)

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cicd-dashboard"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "public_key" {
  description = "Public key for SSH access to EC2 instance"
  type        = string
  # You need to provide your public key here or via terraform.tfvars
}

variable "github_repo_url" {
  description = "GitHub repository URL for the dashboard application"
  type        = string
  default     = "https://github.com/your-username/ci-cd-health-dashboard.git"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Optional: Database configurations (if switching from in-memory)
variable "create_rds" {
  description = "Whether to create RDS instance"
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}
