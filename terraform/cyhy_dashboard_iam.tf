# Create the IAM instance profile for the CyHy Dashboard EC2 server instance

# The instance profile to be used
resource "aws_iam_instance_profile" "cyhy_dashboard" {
  name = format("cyhy_dashboard_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.cyhy_dashboard_instance_role.name
}

# The instance role
resource "aws_iam_role" "cyhy_dashboard_instance_role" {
  name               = format("cyhy_dashboard_instance_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}

# Attach the CloudWatch Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment_cyhy_dashboard" {
  role       = aws_iam_role.cyhy_dashboard_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment_cyhy_dashboard" {
  role       = aws_iam_role.cyhy_dashboard_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
