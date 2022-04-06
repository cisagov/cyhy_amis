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

# Attach the CloudWatch Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment_bod_docker" {
  role       = aws_iam_role.bod_docker_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment_bod_docker" {
  role       = aws_iam_role.bod_docker_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the SES assume role policy to this role as well
resource "aws_iam_role_policy_attachment" "ses_assume_role_policy_attachment_bod_docker" {
  role       = aws_iam_role.bod_docker_instance_role.id
  policy_arn = aws_iam_policy.ses_assume_role_policy.arn
}

# Attach the dmarc-import Elasticsearch assume role policy to this role as well
resource "aws_iam_role_policy_attachment" "dmarc_es_assume_role_policy_attachment_bod_docker" {
  role       = aws_iam_role.bod_docker_instance_role.id
  policy_arn = aws_iam_policy.dmarc_es_assume_role_policy.arn
}

# IAM policy document that that allows the invocation of our Lambda
# functions.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "lambda_bod_docker_doc" {
  count = length(aws_lambda_function.lambdas) > 0 ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [for lambda in aws_lambda_function.lambdas : lambda.arn]
  }
}

# The Lambda policy for our role
resource "aws_iam_role_policy" "lambda_bod_docker_policy" {
  count = length(aws_lambda_function.lambdas) > 0 ? 1 : 0

  role   = aws_iam_role.bod_docker_instance_role.id
  policy = data.aws_iam_policy_document.lambda_bod_docker_doc[0].json
}
