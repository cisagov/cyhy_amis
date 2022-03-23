# ------------------------------------------------------------------------------
# Create an IAM policy document that allows the VPC Flow Log AWS service to
# assume a role.
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "vpc_flow_log_service_assume_role_doc" {
  count = (var.create_bod_flow_logs || var.create_cyhy_flow_logs || var.create_mgmt_flow_logs) ? 1 : 0
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com", ]
    }
  }
}
