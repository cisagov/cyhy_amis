locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "prod"
  production_workspace = replace(terraform.workspace, "prod", "") != terraform.workspace
}
