# Test-only table for validating the CI role's DynamoDB permissions
# (github_actions_oidc.tf: terraform-dynamodb-read-write). Structure follows
# the Terraform Registry's basic aws_dynamodb_table example verbatim; only
# the table `name` was changed, to match the mcp-platform-engineering-*
# name prefix that IAM policy is scoped to.
#
# Commented out (not deleted) to exercise the apply pipeline's destroy path:
# removing this from config makes `terraform plan` show it as a destroy,
# gated by the aws-apply approval step like any other apply.
# resource "aws_dynamodb_table" "test" {
#   name           = "mcp-platform-engineering-test-table"
#   billing_mode   = "PROVISIONED"
#   read_capacity  = 20
#   write_capacity = 20
#   hash_key       = "UserId"
#   range_key      = "GameTitle"
#
#   attribute {
#     name = "UserId"
#     type = "S"
#   }
#
#   attribute {
#     name = "GameTitle"
#     type = "S"
#   }
#
#   attribute {
#     name = "TopScore"
#     type = "N"
#   }
#
#   ttl {
#     attribute_name = "TimeToExist"
#     enabled        = true
#   }
#
#   global_secondary_index {
#     name               = "GameTitleIndex"
#     hash_key           = "GameTitle"
#     range_key          = "TopScore"
#     write_capacity     = 10
#     read_capacity      = 10
#     projection_type    = "INCLUDE"
#     non_key_attributes = ["UserId"]
#   }
#
#   tags = {
#     Name        = "dynamodb-table-1"
#     Environment = "test"
#   }
# }
