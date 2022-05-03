# The S3 bucket where the cyhy-archive compressed archives are stored
resource "aws_s3_bucket" "cyhy_archive" {
  bucket = "${var.cyhy_archive_bucket_name}-${terraform.workspace}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
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
