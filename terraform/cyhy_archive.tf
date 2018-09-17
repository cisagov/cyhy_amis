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

  tags = "${var.tags}"
}

# IAM assume role policy document for the cyhy-archive role
data "aws_iam_policy_document" "cyhy_archive_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The cyhy-archive role
resource "aws_iam_role" "cyhy_archive_role" {
  name = "CyHyArchive_${terraform.workspace}"
  description = "Access for the cyhy-archive process (${terraform.workspace} Terraform workspace)"
  assume_role_policy = "${data.aws_iam_policy_document.cyhy_archive_assume_role_doc.json}"
}

# IAM policy document that that allows S3 PutObject (write) on our
# cyhy-archive bucket.  This will be applied to the cyhy-archive role.
data "aws_iam_policy_document" "s3_cyhy_archive_write_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.cyhy_archive.arn}/*"
    ]
  }
}

# The cyhy-archive S3 policy for our role
resource "aws_iam_role_policy" "s3_cyhy_archive_policy" {
  role = "${aws_iam_role.cyhy_archive_role.id}"
  policy = "${data.aws_iam_policy_document.s3_cyhy_archive_write_doc.json}"
}

# The instance profile to be used by any instances that need the cyhy-archive role
resource "aws_iam_instance_profile" "cyhy_archive" {
  name = "cyhy_archive_${terraform.workspace}"
  role = "${aws_iam_role.cyhy_archive_role.name}"
}
