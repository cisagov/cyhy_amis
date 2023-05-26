resource "aws_s3_bucket" "rules_bucket" {
  bucket = var.rules_bucket_name

  # This is the recommendation of the documentation here:
  # https://registry.terraform.io/providers/hashicorp/aws/3.75.0/docs/resources/s3_bucket_website_configuration#usage-notes
  lifecycle {
    ignore_changes = [
      website
    ]
  }

  tags = { "Application" = "Egress Publish" }
}

# Ensure the S3 bucket is encrypted
resource "aws_s3_bucket_server_side_encryption_configuration" "rules_bucket" {
  bucket = aws_s3_bucket.rules_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# This blocks ANY public access to the bucket or the objects it
# contains, even if misconfigured to allow public access.
resource "aws_s3_bucket_public_access_block" "rules_bucket" {
  bucket = aws_s3_bucket.rules_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Any objects placed into this bucket should be owned by the bucket
# owner. This ensures that even if objects are added by a different
# account, the bucket-owning account retains full control over the
# objects stored in this bucket.
resource "aws_s3_bucket_ownership_controls" "rules_bucket" {
  bucket = aws_s3_bucket.rules_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "rules_bucket" {
  bucket = aws_s3_bucket.rules_bucket.id

  index_document {
    suffix = "all.txt"
  }
  error_document {
    key = "error.html"
  }
}
