resource "aws_s3_bucket" "moe_bucket" {
  bucket = local.production_workspace ? "ncats-moe-data" : format("ncats-moe-data-%s", terraform.workspace)
  acl    = "private"

  tags = merge(
    var.tags,
    {
      "Name" = "MOE bucket"
    },
  )

  lifecycle {
    prevent_destroy = true
  }
}
