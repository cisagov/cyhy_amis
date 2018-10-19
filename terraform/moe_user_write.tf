resource "aws_iam_user" "moe_user_write" {
  # We name the user moe_user_write for production workspaces and
  # moe_user_write_<workspace_name> for non-production workspaces.
  #
  # The reason is that we want to avoid name conflicts when deploying
  # to test environments but share (via terraform import) the users
  # when working in production environments.
  name = "${local.production_workspace ? "moe_user_write" : format("moe_user_write_%s", terraform.workspace)}"

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
