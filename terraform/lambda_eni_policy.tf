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
data "aws_iam_policy_document" "lambda_eni_policy_doc" {
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

# The policy to allow ENI permissions
resource "aws_iam_policy" "lambda_eni_policy" {
  name   = format("lambda_eni_access_%s", local.production_workspace ? "production" : terraform.workspace)
  policy = data.aws_iam_policy_document.lambda_eni_policy_doc.json
}
