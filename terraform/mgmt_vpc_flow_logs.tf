# IAM assume role policy document for the role we're creating
data "aws_iam_policy_document" "mgmt_flow_log_assume_role_doc" {
  count = var.create_mgmt_flow_logs

  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# The IAM role for flow logs
resource "aws_iam_role" "mgmt_flow_log_role" {
  count = var.create_mgmt_flow_logs

  name = "mgmt_flow_log_role_${terraform.workspace}"

  assume_role_policy = data.aws_iam_policy_document.mgmt_flow_log_assume_role_doc[0].json
}

# IAM policy document that that allows some permissions for flow logs.
# This will be applied to the role we are creating.
data "aws_iam_policy_document" "mgmt_flow_log_doc" {
  count = var.create_mgmt_flow_logs

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }
}

# The IAM role policy for the management flow log role
resource "aws_iam_role_policy" "mgmt_flow_log_policy" {
  count = var.create_mgmt_flow_logs

  name = "mgmt_flow_log_policy_${terraform.workspace}"
  role = aws_iam_role.mgmt_flow_log_role[0].id

  policy = data.aws_iam_policy_document.mgmt_flow_log_doc[0].json
}

# The flow log group
resource "aws_cloudwatch_log_group" "mgmt_flow_log_group" {
  count = var.create_mgmt_flow_logs

  name = "mgmt_flow_log_group_${terraform.workspace}"
}

# The flow logs
resource "aws_flow_log" "mgmt_flow_log" {
  count = var.create_mgmt_flow_logs

  log_group_name = aws_cloudwatch_log_group.mgmt_flow_log_group[0].name
  iam_role_arn   = aws_iam_role.mgmt_flow_log_role[0].arn
  vpc_id         = aws_vpc.mgmt_vpc[0].id
  traffic_type   = "ALL"
}

