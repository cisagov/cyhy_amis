# ------------------------------------------------------------------------------
# Create an IAM policy document that allows the EC2 AWS service to
# assume a role.
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_service_assume_role_doc" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", ]
    }
  }
}
