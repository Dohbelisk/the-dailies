# S3 Bucket for Admin Portal Static Hosting
# Free tier: 5GB storage, 20,000 GET, 2,000 PUT requests

resource "aws_s3_bucket" "admin_portal" {
  bucket = "${var.project_name}-admin-portal"

  tags = {
    Name = "${var.project_name}-admin-portal"
  }
}

# Block public access (CloudFront will serve content)
resource "aws_s3_bucket_public_access_block" "admin_portal" {
  bucket = aws_s3_bucket.admin_portal.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket versioning (optional, but useful for rollbacks)
resource "aws_s3_bucket_versioning" "admin_portal" {
  bucket = aws_s3_bucket.admin_portal.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Origin Access Control for CloudFront
resource "aws_cloudfront_origin_access_control" "admin_portal" {
  name                              = "${var.project_name}-admin-oac"
  description                       = "OAC for admin portal S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "admin_portal" {
  bucket = aws_s3_bucket.admin_portal.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.admin_portal.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.admin_portal.arn
          }
        }
      }
    ]
  })
}
