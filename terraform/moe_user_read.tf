resource "aws_iam_user" "moe_user_read" {
  # We name the user moe-user-read for production workspaces and
  # moe-user-read-<workspace_name> for non-production workspaces.
  #
  # The reason is that we want to avoid name conflicts when deploying
  # to test environments but share (via terraform import) the users
  # when working in production environments.
  name = local.production_workspace ? "moe-user-read" : format("moe-user-read-%s", terraform.workspace)

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_access_key" "moe_user_read" {
  user = aws_iam_user.moe_user_read.name
}

# IAM policy document that that allows read permissions on the MOE
# bucket.  This will be applied to the moe_user_read role.
data "aws_iam_policy_document" "moe_read_doc" {
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

# The S3 policy for our role
resource "aws_iam_user_policy" "moe_read_policy" {
  user   = aws_iam_user.moe_user_read.name
  policy = data.aws_iam_policy_document.moe_read_doc.json
}
