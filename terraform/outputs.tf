# Outputs for reference and GitHub Actions

output "backend_public_ip" {
  description = "Public IP of the backend EC2 instance"
  value       = aws_eip.backend.public_ip
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "http://${aws_eip.backend.public_ip}"
}

output "admin_portal_bucket" {
  description = "S3 bucket name for admin portal"
  value       = aws_s3_bucket.admin_portal.id
}

output "admin_portal_url" {
  description = "CloudFront URL for admin portal"
  value       = "https://${aws_cloudfront_distribution.admin_portal.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = aws_cloudfront_distribution.admin_portal.id
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.backend.id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

# Output for GitHub Actions secrets
output "github_actions_config" {
  description = "Configuration values for GitHub Actions secrets"
  value = {
    AWS_REGION                   = var.aws_region
    EC2_HOST                     = aws_eip.backend.public_ip
    S3_BUCKET                    = aws_s3_bucket.admin_portal.id
    CLOUDFRONT_DISTRIBUTION_ID   = aws_cloudfront_distribution.admin_portal.id
    API_URL                      = "http://${aws_eip.backend.public_ip}"
    ADMIN_URL                    = "https://${aws_cloudfront_distribution.admin_portal.domain_name}"
  }
}
