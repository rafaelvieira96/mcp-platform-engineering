variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
  default     = "my-mcp-terraform-test-part2"
}

variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}
