# IAM policy document that allows us to assume a role that allows
# sending of emails via SES.
data "aws_iam_policy_document" "ses_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    resources = [
      var.ses_role_arn,
    ]
  }
}

# Create a policy that can be attached to any role that needs to send email
# using SES.
resource "aws_iam_policy" "ses_assume_role_policy" {
  name   = format("ses_assume_role_%s", local.production_workspace ? "production" : terraform.workspace)
  policy = data.aws_iam_policy_document.ses_assume_role_doc.json
}
