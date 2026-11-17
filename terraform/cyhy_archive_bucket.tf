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

# Add a lifecycle configuration to the bucket to transition any cyhy-archive objects to
# progressively slower and/or more expensive to access, but cheaper to store, storage
# classes. The dates to transition take into account the minimum retention period
# requirements for the storage class the object is transitioning from.
resource "aws_s3_bucket_lifecycle_configuration" "cyhy_archive" {
  bucket = aws_s3_bucket.cyhy_archive.id

  rule {
    id     = var.cyhy_archive_bucket_lifecycle_rule_name
    status = "Enabled"

    filter {
      # This matches the prefix for the archive files produced by the cyhy-archive
      # script.
      prefix = "cyhy_archive_"
    }

    # After 30 days, transition archive objects to the Glacier Instant Retrieval
    # storage class. This storage class has a 90 day minimum retention period.
    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }

    # After 120 days (30 in Standard and 90 in Glacier Instant Retrieval), transition
    # archive objects to the Glacier Deep Archive storage class. This storage class has
    # a 180 day minimum retention period. This is the final storage class for these
    # objects.
    transition {
      days          = 120
      storage_class = "DEEP_ARCHIVE"
    }
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
