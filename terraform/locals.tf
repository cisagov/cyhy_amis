locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "production"
  production_workspace = "${replace(terraform.workspace, "production", "") != terraform.workspace}"
}
