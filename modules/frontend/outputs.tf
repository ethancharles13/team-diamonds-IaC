output "website_url" {
  description = "The CloudFront URL of the deployed frontend website"
  value       = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}