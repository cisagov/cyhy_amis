# The roles we're creating for the Lambda functions
resource "aws_iam_role" "lambda_roles" {
  for_each = local.bod_lambda_types

  name               = format("bod_%s_lambda_role_%s", each.value, local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.lambda_service_assume_role_doc.json
}

# IAM policy documents that that allows some CloudWatch permissions
# for our Lambda functions.  This will allow the Lambda functions to
# generate log output in CloudWatch.  These will be applied to the
# roles we are creating.
data "aws_iam_policy_document" "lambda_cloudwatch_docs" {
  for_each = local.bod_lambda_types

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda_logs[each.value].arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.lambda_logs[each.value].arn}:*",
    ]
  }
}

# The CloudWatch policies for our roles
resource "aws_iam_role_policy" "lambda_cloudwatch_policies" {
  for_each = local.bod_lambda_types

  role   = aws_iam_role.lambda_roles[each.value].id
  policy = data.aws_iam_policy_document.lambda_cloudwatch_docs[each.value].json
}
# The Lambda ENI policy attachments for our roles
resource "aws_iam_role_policy_attachment" "lambda_eni_policy_attachment_bod" {
  for_each = local.bod_lambda_types

  role       = aws_iam_role.lambda_roles[each.value].id
  policy_arn = aws_iam_policy.lambda_eni_policy.arn
}

# The AWS Lambda functions that perform the scans
resource "aws_lambda_function" "lambdas" {
  for_each = var.bod_lambda_functions

  # Terraform cannot access buckets that are not in the provider's
  # region.  This limitation means that we have to create
  # region-specific buckets.
  s3_bucket     = "${var.bod_lambda_function_bucket}-${var.aws_region}"
  s3_key        = each.value.lambda_file
  function_name = each.value.lambda_name
  role          = aws_iam_role.lambda_roles[each.key].arn
  handler       = "lambda_handler.handler"
  runtime       = "python3.7"
  timeout       = 900
  memory_size   = 128
  description   = "Lambda function for performing BOD 18-01 ${each.key} scans"
  vpc_config {
    subnet_ids = [
      aws_subnet.bod_lambda_subnet.id,
    ]

    security_group_ids = [
      aws_security_group.bod_lambda_sg.id,
    ]
  }
}

# The CloudWatch log groups for the Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.bod_lambda_types

  name              = "/aws/lambda/${aws_lambda_function.lambdas[each.value].function_name}"
  retention_in_days = 30
}
