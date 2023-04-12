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

# Attach the MOE S3 bucket read policy
resource "aws_iam_user_policy_attachment" "moe_bucket_read_policy_attachment_moe_user" {
  user       = aws_iam_user.moe_user_read.name
  policy_arn = aws_iam_policy.moe_bucket_read.arn
}
