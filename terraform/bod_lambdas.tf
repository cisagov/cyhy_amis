# IAM assume role policy document for the roles we're creating for the
# lambda functions
data "aws_iam_policy_document" "lambda_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# The roles we're creating for the lambda functions
resource "aws_iam_role" "lambda_roles" {
  count = length(var.scan_types)

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_doc.json
}

# IAM policy documents that that allows some Cloudwatch permissions
# for our Lambda functions.  This will allow the Lambda functions to
# generate log output in Cloudwatch.  These will be applied to the
# roles we are creating.
data "aws_iam_policy_document" "lambda_cloudwatch_docs" {
  count = length(aws_cloudwatch_log_group.lambda_logs)

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda_logs[count.index].arn,
    ]
  }
}

# The CloudWatch policies for our roles
resource "aws_iam_role_policy" "lambda_cloudwatch_policies" {
  count = length(aws_iam_role.lambda_roles)

  role   = aws_iam_role.lambda_roles[count.index].id
  policy = data.aws_iam_policy_document.lambda_cloudwatch_docs[count.index].json
}

# IAM policy documents that that allows some EC2 permissions
# for our Lambda functions.  This will allow the Lambda functions to
# create and destroy ENI resources, as described here:
# https://docs.aws.amazon.com/lambda/latest/dg/vpc.html.
#
# It would be great if there were a way to add a condition to reduce
# the number of resources to which this policy can apply, but I don't
# see a way to do that.
#
# These policy documents will be applied to the roles we are creating.
data "aws_iam_policy_document" "lambda_ec2_docs" {
  count = length(var.scan_types)

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]

    resources = [
      "*",
    ]
  }
}

# The EC2 policies for our roles
resource "aws_iam_role_policy" "lambda_ec2_policies" {
  count = length(aws_iam_role.lambda_roles)

  role   = aws_iam_role.lambda_roles[count.index].id
  policy = data.aws_iam_policy_document.lambda_ec2_docs[count.index].json
}

# The AWS Lambda functions that perform the scans
resource "aws_lambda_function" "lambdas" {
  count = length(aws_iam_role.lambda_roles)

  # Terraform cannot access buckets that are not in the provider's
  # region.  This limitation means that we have to create
  # region-specific buckets.
  s3_bucket     = "${var.lambda_function_bucket}-${var.aws_region}"
  s3_key        = var.lambda_function_keys[var.scan_types[count.index]]
  function_name = var.lambda_function_names[var.scan_types[count.index]]
  role          = aws_iam_role.lambda_roles[count.index].arn
  handler       = "lambda_handler.handler"
  runtime       = "python3.6"
  timeout       = 900
  memory_size   = 128
  description   = "Lambda function for performing BOD 18-01 ${var.scan_types[count.index]} scans"
  vpc_config {
    subnet_ids = [
      aws_subnet.bod_lambda_subnet.id,
    ]

    security_group_ids = [
      aws_security_group.bod_lambda_sg.id,
    ]
  }

  tags = var.tags
}

# The Cloudwatch log groups for the Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  count = length(aws_lambda_function.lambdas)

  name              = "/aws/lambda/${aws_lambda_function.lambdas[count.index].function_name}"
  retention_in_days = 30

  tags = var.tags
}
