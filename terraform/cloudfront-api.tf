# CloudFront Distribution for API (HTTPS termination)
# This allows the HTTPS admin portal to call the API without mixed content issues

resource "aws_cloudfront_distribution" "api" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "The Dailies API"
  price_class     = "PriceClass_100"

  origin {
    domain_name = aws_instance.backend.public_dns
    origin_id   = "EC2-API"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "EC2-API"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

output "api_cloudfront_url" {
  description = "CloudFront URL for API (HTTPS)"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}"
}

output "api_cloudfront_distribution_id" {
  description = "CloudFront distribution ID for API"
  value       = aws_cloudfront_distribution.api.id
}
