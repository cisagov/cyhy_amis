resource "aws_s3_bucket" "rules_bucket" {
  bucket = var.rules_bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  website {
    index_document = "all.txt"
    error_document = "error.html"
  }

  tags = merge(
    var.tags,
    {
      "Application" = "Egress Publish"
    },
  )
}
