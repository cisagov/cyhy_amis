# The S3 bucket where the cyhy-archive compressed archives are stored
resource "aws_s3_bucket" "cyhy_archive" {
  bucket = "${var.cyhy_archive_bucket_name}-${terraform.workspace}"
}

# Ensure the S3 bucket is encrypted
resource "aws_s3_bucket_server_side_encryption_configuration" "cyhy_archive" {
  bucket = aws_s3_bucket.cyhy_archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# This blocks ANY public access to the bucket or the objects it
# contains, even if misconfigured to allow public access.
resource "aws_s3_bucket_public_access_block" "cyhy_archive" {
  bucket = aws_s3_bucket.cyhy_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Any objects placed into this bucket should be owned by the bucket
# owner. This ensures that even if objects are added by a different
# account, the bucket-owning account retains full control over the
# objects stored in this bucket.
resource "aws_s3_bucket_ownership_controls" "cyhy_archive" {
  bucket = aws_s3_bucket.cyhy_archive.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# IAM policy document that that allows S3 PutObject (write) on our
# cyhy-archive bucket.  This will be applied to the cyhy-archive role.
data "aws_iam_policy_document" "s3_cyhy_archive_write_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cyhy_archive.arn}/*",
    ]
  }
}

# Create a policy that can be attached to any role that needs to write to the
# cyhy-archive S3 bucket.
resource "aws_iam_policy" "s3_cyhy_archive_write_policy" {
  name   = format("s3_cyhy_archive_write_%s", local.production_workspace ? "production" : terraform.workspace)
  policy = data.aws_iam_policy_document.s3_cyhy_archive_write_doc.json
}
