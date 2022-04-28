# Infrastructure related to the assessment data import lambda

# The role we're creating for the Lambda function
resource "aws_iam_role" "adi_lambda_role" {
  name               = format("adi_lambda_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.lambda_service_assume_role_doc.json
}

# IAM policy document that that allows some CloudWatch permissions
# for our Lambda function.  This will allow the Lambda function to
# generate log output in CloudWatch.  This will be applied to the
# role we are creating.
data "aws_iam_policy_document" "adi_lambda_cloudwatch_doc" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      aws_cloudwatch_log_group.adi_lambda_logs.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.adi_lambda_logs.arn}:*",
    ]
  }
}

# The CloudWatch policy for our role
resource "aws_iam_role_policy" "adi_lambda_cloudwatch_policy" {
  role   = aws_iam_role.adi_lambda_role.id
  policy = data.aws_iam_policy_document.adi_lambda_cloudwatch_doc.json
}

# IAM policy document that that allows some EC2 permissions
# for our Lambda function.  This will allow the Lambda function to
# create and destroy ENI resources, as described here:
# https://docs.aws.amazon.com/lambda/latest/dg/vpc.html.
#
# It would be great if there were a way to add a condition to reduce
# the number of resources to which this policy can apply, but I don't
# see a way to do that.
#
# This policy document will be applied to the role we are creating.
data "aws_iam_policy_document" "adi_lambda_ec2_doc" {
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

# The EC2 policy for our role (needed to run the Lambda from within our VPC)
resource "aws_iam_role_policy" "adi_lambda_ec2_policy" {
  role   = aws_iam_role.adi_lambda_role.id
  policy = data.aws_iam_policy_document.adi_lambda_ec2_doc.json
}

# IAM policy document that that allows some S3 permissions
# for our Lambda function.  This will allow the Lambda function to
# get the assessment data JSON file from the bucket and delete it after
# the data has been imported to the database.  This will be applied to the
# role we are creating.
data "aws_iam_policy_document" "adi_lambda_s3_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${data.aws_s3_bucket.assessment_data.arn}/*",
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "adi_lambda_s3_policy" {
  role   = aws_iam_role.adi_lambda_role.id
  policy = data.aws_iam_policy_document.adi_lambda_s3_doc.json
}

# IAM policy document that that allows some SSM permissions
# for our Lambda function.  This will allow the Lambda function to
# get the SSM parameters that contain the credentials needed to access the
# assessment database.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "adi_lambda_ssm_doc" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.assessment_data_import_ssm_db_name}",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.assessment_data_import_ssm_db_user}",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.assessment_data_import_ssm_db_password}",
    ]
  }
}

# The SSM policy for our role
resource "aws_iam_role_policy" "adi_lambda_ssm_policy" {
  role   = aws_iam_role.adi_lambda_role.id
  policy = data.aws_iam_policy_document.adi_lambda_ssm_doc.json
}

# The S3 bucket where the assessment data is stored
# Terraform code for this bucket is in:
#   https://github.com/cisagov/assessment-data-import-terraform
data "aws_s3_bucket" "assessment_data" {
  bucket = format("%s-%s", var.assessment_data_s3_bucket, local.production_workspace ? "production" : terraform.workspace)
}

# The S3 bucket where the assessment data import Lambda function is stored
# Terraform code for this bucket is in:
#   https://github.com/cisagov/assessment-data-import-terraform
data "aws_s3_bucket" "adi_lambda" {
  bucket = format("%s-%s", var.assessment_data_import_lambda_s3_bucket, local.production_workspace ? "production" : terraform.workspace)
}

# The AWS Lambda function that imports the assessment data to our database
# Note that this Lambda runs from within the CyHy private subnet
resource "aws_lambda_function" "adi_lambda" {
  s3_bucket     = data.aws_s3_bucket.adi_lambda.id
  s3_key        = var.assessment_data_import_lambda_s3_key
  function_name = format("assessment_data_import-%s", terraform.workspace)
  role          = aws_iam_role.adi_lambda_role.arn
  handler       = "lambda_handler.handler"
  runtime       = "python3.8"
  timeout       = 300
  memory_size   = 128
  description   = "Lambda function for importing assessment data"

  # This Lambda requires the database to function
  depends_on = [
    aws_instance.cyhy_mongo,
  ]

  vpc_config {
    subnet_ids = [
      aws_subnet.cyhy_private_subnet.id,
    ]

    security_group_ids = [
      aws_security_group.adi_lambda_sg.id,
    ]
  }

  environment {
    variables = {
      s3_bucket       = data.aws_s3_bucket.assessment_data.id
      data_filename   = var.assessment_data_filename
      db_hostname     = var.assessment_data_import_db_hostname
      db_port         = var.assessment_data_import_db_port
      ssm_db_name     = var.assessment_data_import_ssm_db_name
      ssm_db_user     = var.assessment_data_import_ssm_db_user
      ssm_db_password = var.assessment_data_import_ssm_db_password
    }
  }
}

# Permission to allow the Lambda to get notifications from our
# assessment data bucket
resource "aws_lambda_permission" "adi_lambda_allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.adi_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.assessment_data.arn
}

# Create the notification that triggers our Lambda function to run whenever
# an object is created in our assessment data bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.assessment_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.adi_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.assessment_data_filename
  }
}

# The CloudWatch log group for the Lambda functions
resource "aws_cloudwatch_log_group" "adi_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.adi_lambda.function_name}"
  retention_in_days = 30
}
