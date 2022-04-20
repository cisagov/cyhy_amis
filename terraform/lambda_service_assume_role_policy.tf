# ------------------------------------------------------------------------------
# Create an IAM policy document that allows the Lambda AWS service to
# assume a role.
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_service_assume_role_doc" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", ]
    }
  }
}
