# Frontend is hosted via an S3 bucket and cloudfront

resource "aws_s3_bucket" "team_diamonds_s3" {
  bucket = "team-diamonds-s3"
}

# Block all public access directly to the S3 bucket
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.team_diamonds_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control to securely read from S3
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "team-diamonds-frontend-oac"
  description                       = "OAC for Team Diamonds Frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.team_diamonds_s3.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.team_diamonds_s3.bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.team_diamonds_s3.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # SPA Routing: Redirect 404/403 to index.html (useful for React routing)
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Bucket Policy granting CloudFront access to S3 via OAC
resource "aws_s3_bucket_policy" "cloudfront_read_policy" {
  bucket = aws_s3_bucket.team_diamonds_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.team_diamonds_s3.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend_distribution.arn
          }
        }
      }
    ]
  })
}

# SSM Parameters

resource "aws_ssm_parameter" "front_end_bucket_name" {
  name  = "front-end-bucket"
  type  = "String"
  value = aws_s3_bucket.team_diamonds_s3.id
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  name  = "cloudfront-distribution-id"
  type  = "String"
  value = aws_cloudfront_distribution.frontend_distribution.id
}

resource "aws_ssm_parameter" "website_url" {
  name  = "website-url"
  type  = "String"
  value = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}