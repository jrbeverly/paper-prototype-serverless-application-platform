output "dynamodb_table_name" {
  description = "Name of the DynamoDB items table."
  value       = aws_dynamodb_table.items.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB items table."
  value       = aws_dynamodb_table.items.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.lambda.arn
}

output "api_endpoint" {
  description = "Invoke URL for the API Gateway HTTP API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (HTTPS endpoint for the application)."
  value       = aws_cloudfront_distribution.app.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidations)."
  value       = aws_cloudfront_distribution.app.id
}

output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend static assets."
  value       = aws_s3_bucket.frontend.id
}

output "app_url" {
  description = "Application HTTPS endpoint — custom domain if configured, otherwise the CloudFront default."
  value       = var.domain_name != null ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.app.domain_name}"
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate, or null when no custom domain is configured."
  value       = var.domain_name != null ? aws_acm_certificate.app[0].arn : null
}
