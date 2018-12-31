# IAM assume role policy document for the roles we're creating for the
# lambda functions
data "aws_iam_policy_document" "lambda_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# The roles we're creating for the lambda functions
resource "aws_iam_role" "lambda_roles" {
  count = "${length(var.scan_types)}"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_doc.json}"
}

# IAM policy documents that that allows some Cloudwatch permissions
# for our Lambda functions.  This will allow the Lambda functions to
# generate log output in Cloudwatch.  These will be applied to the
# roles we are creating.
data "aws_iam_policy_document" "lambda_cloudwatch_docs" {
  count = "${length(var.scan_types)}"

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.lambda_logs.*.arn[count.index]}",
    ]
  }
}

# The CloudWatch policies for our roles
resource "aws_iam_role_policy" "lambda_cloudwatch_policies" {
  count = "${length(var.scan_types)}"

  role = "${aws_iam_role.lambda_roles.*.id[count.index]}"
  policy = "${data.aws_iam_policy_document.lambda_cloudwatch_docs.*.json[count.index]}"
}

# The AWS Lambda functions that perform the scans
resource "aws_lambda_function" "lambdas" {
  count = "${length(var.scan_types)}"

  filename = "${var.lambda_function_zip_files[var.scan_types[count.index]]}"
  source_code_hash = "${base64sha256(file(var.lambda_function_zip_files[var.scan_types[count.index]]))}"
  function_name = "${var.lambda_function_names[var.scan_types[count.index]]}"
  role = "${aws_iam_role.lambda_roles.*.arn[count.index]}"
  handler = "lambda_handler.handler"
  runtime = "python3.6"
  timeout = 900
  memory_size = 128
  description = "Lambda function for performing BOD 18-01 ${var.scan_types[count.index]} scans"
  vpc_config {
    subnet_ids = [
      "${aws_subnet.bod_lambda_subnet.id}"
    ]

    security_group_ids = [
      "${aws_security_group.bod_lambda_sg.id}"
    ]
  }

  tags = "${var.tags}"
}

# The Cloudwatch log groups for the Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  count = "${length(var.scan_types)}"

  name = "/aws/lambda/${aws_lambda_function.lambdas.*.function_name[count.index]}"
  retention_in_days = 30

  tags = "${var.tags}"
}
