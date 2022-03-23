# Create the IAM instance profile for the BOD Docker EC2 server instance

# The instance profile to be used
resource "aws_iam_instance_profile" "bod_docker" {
  name = format("bod_docker_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.bod_docker_instance_role.name
}

# The instance role
resource "aws_iam_role" "bod_docker_instance_role" {
  name               = format("bod_docker_instance_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}

# IAM policy document that that allows the invocation of our Lambda
# functions.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "lambda_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    # I should be able to use splat syntax here
    resources = [
      aws_lambda_function.lambdas[0].arn,
      aws_lambda_function.lambdas[1].arn,
      aws_lambda_function.lambdas[2].arn,
    ]
  }
}

# The Lambda policy for our role
resource "aws_iam_role_policy" "lambda_bod_docker_policy" {
  role   = aws_iam_role.bod_docker_instance_role.id
  policy = data.aws_iam_policy_document.lambda_bod_docker_doc.json
}

# IAM policy document that allows us to assume a role that allows
# reading of the dmarc-import Elasticsearch database.  This will be
# applied to the role we are creating.
data "aws_iam_policy_document" "es_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      var.dmarc_import_es_role_arn,
    ]
  }
}

# The Elasticsearch policy for our role
resource "aws_iam_role_policy" "es_bod_docker_policy" {
  role   = aws_iam_role.bod_docker_instance_role.id
  policy = data.aws_iam_policy_document.es_bod_docker_doc.json
}

# IAM policy document that allows us to assume a role that allows
# sending of emails via SES.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "ses_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      var.ses_role_arn,
    ]
  }
}

# The SES policy for our role
resource "aws_iam_role_policy" "ses_bod_docker_policy" {
  role   = aws_iam_role.bod_docker_instance_role.id
  policy = data.aws_iam_policy_document.ses_bod_docker_doc.json
}
