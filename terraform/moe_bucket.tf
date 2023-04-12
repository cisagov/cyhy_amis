resource "aws_s3_bucket" "moe_bucket" {
  bucket = local.production_workspace ? "ncats-moe-data" : format("ncats-moe-data-%s", terraform.workspace)
  acl    = "private"

  tags = { "Name" = "MOE bucket" }

  lifecycle {
    prevent_destroy = true
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
