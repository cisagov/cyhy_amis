resource "aws_iam_user" "moe_user_write" {
  name = "moe_user_write_${terraform.workspace}"
}

resource "aws_iam_access_key" "moe_user_write" {
  user = "${aws_iam_user.moe_user_write.name}"
}

# IAM policy document that that allows write permissions on the MOE
# bucket.  This will be applied to the moe_user_write role.
data "aws_iam_policy_document" "moe_write_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::ncats-moe-data"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::ncats-moe-data/*"
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_user_policy" "moe_write_policy" {
  user = "${aws_iam_user.moe_user_write.name}"
  policy = "${data.aws_iam_policy_document.moe_write_doc.json}"
}
