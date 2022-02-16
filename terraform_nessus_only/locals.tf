# The AWS account ID being used
data "aws_caller_identity" "current" {}

locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "prod"
  production_workspace = replace(terraform.workspace, "prod", "") != terraform.workspace
}
