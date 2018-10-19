resource "aws_iam_user" "moe_user_read" {
  name = "moe_user_read_${terraform.workspace}"
}

resource "aws_iam_access_key" "moe_user_read" {
  user = "${aws_iam_user.moe_user_read.name}"
}

# IAM policy document that that allows read permissions on the MOE
# bucket.  This will be applied to the moe_user_read role.
data "aws_iam_policy_document" "moe_read_doc" {
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
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::ncats-moe-data/*"
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_user_policy" "moe_read_policy" {
  user = "${aws_iam_user.moe_user_read.name}"
  policy = "${data.aws_iam_policy_document.moe_read_doc.json}"
}
