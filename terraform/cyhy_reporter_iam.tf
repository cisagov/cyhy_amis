# Create the IAM instance profile for the CyHy Reporter EC2 server instance

# The instance profile to be used
resource "aws_iam_instance_profile" "cyhy_reporter" {
  name = format("cyhy_reporter_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.cyhy_reporter_instance_role.name
}

# The instance role
resource "aws_iam_role" "cyhy_reporter_instance_role" {
  name               = format("cyhy_reporter_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}

# Attach the CloudWatch Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment_cyhy_reporter" {
  role       = aws_iam_role.cyhy_reporter_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment_cyhy_reporter" {
  role       = aws_iam_role.cyhy_reporter_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM policy document that allows us to assume a role that allows
# sending of emails via SES.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "ses_cyhy_reporter_doc" {
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
resource "aws_iam_role_policy" "ses_cyhy_reporter_policy" {
  role   = aws_iam_role.cyhy_reporter_instance_role.id
  policy = data.aws_iam_policy_document.ses_cyhy_reporter_doc.json
}
