variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" # Best for free tier and CloudFront
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "the-dailies"
}

variable "ec2_instance_type" {
  description = "EC2 instance type (t2.micro is free tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "mongodb_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
}

variable "cors_origins" {
  description = "Allowed CORS origins (comma-separated)"
  type        = string
  default     = ""
}

# Optional variables
variable "anthropic_api_key" {
  description = "Anthropic API key for AI puzzle generation"
  type        = string
  sensitive   = true
  default     = ""
}

variable "smtp_user" {
  description = "SMTP user for email notifications"
  type        = string
  default     = ""
}

variable "smtp_pass" {
  description = "SMTP password for email notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "feedback_email" {
  description = "Email address for feedback notifications"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub token for auto-creating issues"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository for auto-creating issues"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}
