resource "aws_iam_user" "moe_user_write" {
  # We name the user moe-user-write for production workspaces and
  # moe-user-write-<workspace_name> for non-production workspaces.
  #
  # The reason is that we want to avoid name conflicts when deploying
  # to test environments but share (via terraform import) the users
  # when working in production environments.
  name = "${local.production_workspace ? "moe-user-write" : format("moe-user-write-%s", terraform.workspace)}"

  lifecycle {
    prevent_destroy = true
  }
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
      "${aws_s3_bucket.moe_bucket.arn}"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.moe_bucket.arn}/*"
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_user_policy" "moe_write_policy" {
  user = "${aws_iam_user.moe_user_write.name}"
  policy = "${data.aws_iam_policy_document.moe_write_doc.json}"
}
