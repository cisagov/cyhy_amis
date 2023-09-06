# Infrastructure related to the findings data import lambda

# The role we're creating for the Lambda function
resource "aws_iam_role" "fdi_lambda_role" {
  name               = format("fdi_lambda_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.lambda_service_assume_role_doc.json
}

# IAM policy document that that allows some CloudWatch permissions
# for our Lambda function.  This will allow the Lambda function to
# generate log output in CloudWatch.  This will be applied to the
# role we are creating.
data "aws_iam_policy_document" "fdi_lambda_cloudwatch_doc" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      aws_cloudwatch_log_group.fdi_lambda_logs.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.fdi_lambda_logs.arn}:*",
    ]
  }
}

# The CloudWatch policy for our role
resource "aws_iam_role_policy" "fdi_lambda_cloudwatch_policy" {
  role   = aws_iam_role.fdi_lambda_role.id
  policy = data.aws_iam_policy_document.fdi_lambda_cloudwatch_doc.json
}

# The Lambda ENI policy attachment for our role (needed to run the Lambda from within our VPC)
resource "aws_iam_role_policy_attachment" "lambda_eni_policy_attachment_fdi" {
  role       = aws_iam_role.fdi_lambda_role.id
  policy_arn = aws_iam_policy.lambda_eni_policy.arn
}

# IAM policy document that that allows some S3 permissions
# for our Lambda function.  This will allow the Lambda function to
# get the findings data JSON file from the bucket and delete it after
# the data has been imported to the database.  This will be applied to the
# role we are creating.
data "aws_iam_policy_document" "fdi_lambda_s3_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    resources = [
      "${data.aws_s3_bucket.findings_data.arn}/*",
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "fdi_lambda_s3_policy" {
  role   = aws_iam_role.fdi_lambda_role.id
  policy = data.aws_iam_policy_document.fdi_lambda_s3_doc.json
}

# IAM policy document that that allows some SSM permissions
# for our Lambda function.  This will allow the Lambda function to
# get the SSM parameters that contain the credentials needed to access the
# findings database.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "fdi_lambda_ssm_doc" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.findings_data_import_ssm_db_name}",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.findings_data_import_ssm_db_user}",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.findings_data_import_ssm_db_password}",
    ]
  }
}

# The SSM policy for our role
resource "aws_iam_role_policy" "fdi_lambda_ssm_policy" {
  role   = aws_iam_role.fdi_lambda_role.id
  policy = data.aws_iam_policy_document.fdi_lambda_ssm_doc.json
}

# The S3 bucket where the findings data is stored
# Terraform code for this bucket is in:
#   https://github.com/cisagov/findings-data-import-terraform
data "aws_s3_bucket" "findings_data" {
  bucket = format("%s-%s", var.findings_data_s3_bucket, local.production_workspace ? "production" : terraform.workspace)
}

# The AWS Lambda function that imports the findings data to our database
# Note that this Lambda runs from within the CyHy private subnet
resource "aws_lambda_function" "fdi_lambda" {
  description   = var.findings_data_import_lambda_description
  function_name = format("findings_data_import-%s", local.production_workspace ? "production" : terraform.workspace)
  handler       = var.findings_data_import_lambda_handler
  memory_size   = 128
  role          = aws_iam_role.fdi_lambda_role.arn
  runtime       = "python3.9"
  s3_bucket     = data.aws_s3_bucket.lambda_deployment_artifacts.id
  s3_key        = var.findings_data_import_lambda_s3_key
  timeout       = 300

  # This Lambda requires the database to function
  depends_on = [
    aws_instance.cyhy_mongo,
  ]

  environment {
    variables = {
      db_hostname     = var.findings_data_import_db_hostname
      db_port         = var.findings_data_import_db_port
      field_map       = var.findings_data_field_map
      file_suffix     = var.findings_data_input_suffix
      s3_bucket       = data.aws_s3_bucket.findings_data.id
      save_failed     = var.findings_data_save_failed
      save_succeeded  = var.findings_data_save_succeeded
      ssm_db_name     = var.findings_data_import_ssm_db_name
      ssm_db_password = var.findings_data_import_ssm_db_password
      ssm_db_user     = var.findings_data_import_ssm_db_user
    }
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.fdi_lambda_sg.id,
    ]

    subnet_ids = [
      aws_subnet.cyhy_private_subnet.id,
    ]
  }
}

# Permission to allow the Lambda to get notifications from our
# findings data bucket
resource "aws_lambda_permission" "fdi_lambda_allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fdi_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.findings_data.arn
}

# Create the notification configuration for the findings data bucket
resource "aws_s3_bucket_notification" "fdi_lambda" {
  bucket = data.aws_s3_bucket.findings_data.id

  # Trigger the appropriate Lambda function whenever an object with the configured
  # suffix is created in the bucket.
  lambda_function {
    lambda_function_arn = aws_lambda_function.fdi_lambda.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = var.findings_data_input_suffix
  }

  # Notify the appropriate SNS topic for fdi failures whenever an object is created
  # with the configured prefix and suffix.
  topic {
    topic_arn     = aws_sns_topic.fdi_failure_alarm.arn
    events        = ["s3:ObjectCreated:Copy"]
    filter_prefix = var.findings_data_import_lambda_failure_prefix
    filter_suffix = var.findings_data_import_lambda_failure_suffix
  }

}

# The CloudWatch log group for the Lambda functions
resource "aws_cloudwatch_log_group" "fdi_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.fdi_lambda.function_name}"
  retention_in_days = 30
}
