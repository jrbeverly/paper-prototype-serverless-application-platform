variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_endpoint" {
  description = "Override the DynamoDB endpoint for local development (e.g. http://localhost:8000)."
  type        = string
  default     = null
}

variable "lambda_zip_path" {
  description = "Path to the backend Lambda deployment package (zip). Build with 'make build-backend'."
  type        = string
  default     = "../backend/backend.zip"
}

variable "domain_name" {
  description = "Optional custom domain for the CloudFront distribution (e.g. app.example.com). Requires hosted_zone_id for automated DNS validation."
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID used for ACM DNS validation and the CloudFront alias record. Required when domain_name is set."
  type        = string
  default     = null
}
