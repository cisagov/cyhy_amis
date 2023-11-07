resource "aws_s3_bucket" "moe_bucket" {
  bucket = local.production_workspace ? "ncats-moe-data" : format("ncats-moe-data-%s", terraform.workspace)

  tags = { "Name" = "MOE bucket" }

  lifecycle {
    prevent_destroy = true
  }
}

# Ensure the S3 bucket is encrypted
resource "aws_s3_bucket_server_side_encryption_configuration" "moe_bucket" {
  bucket = aws_s3_bucket.moe_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# This blocks ANY public access to the bucket or the objects it
# contains, even if misconfigured to allow public access.
resource "aws_s3_bucket_public_access_block" "moe_bucket" {
  bucket = aws_s3_bucket.moe_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Any objects placed into this bucket should be owned by the bucket
# owner. This ensures that even if objects are added by a different
# account, the bucket-owning account retains full control over the
# objects stored in this bucket.
resource "aws_s3_bucket_ownership_controls" "moe_bucket" {
  bucket = aws_s3_bucket.moe_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# IAM policy document that that allows read permissions on the MOE bucket.
data "aws_iam_policy_document" "moe_bucket_read_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.moe_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.moe_bucket.arn}/*",
    ]
  }
}

# The policy that allows read access to the MOE S3 bucket
resource "aws_iam_policy" "moe_bucket_read" {
  name   = format("moe_bucket_read_%s", local.production_workspace ? "production" : terraform.workspace)
  policy = data.aws_iam_policy_document.moe_bucket_read_doc.json
}

# IAM policy document that that allows write permissions on the MOE bucket.
data "aws_iam_policy_document" "moe_bucket_write_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.moe_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.moe_bucket.arn}/*",
    ]
  }
}

# The policy that allows write access to the MOE S3 bucket
resource "aws_iam_policy" "moe_bucket_write" {
  name   = format("moe_bucket_write_%s", local.production_workspace ? "production" : terraform.workspace)
  policy = data.aws_iam_policy_document.moe_bucket_write_doc.json
}
