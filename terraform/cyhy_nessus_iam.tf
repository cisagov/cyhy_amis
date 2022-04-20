# Create the IAM instance profile for the CyHy Vulnscan EC2 server instances

# The instance profile to be used
resource "aws_iam_instance_profile" "cyhy_nessus" {
  name = format("cyhy_vulnscan_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.cyhy_nessus_instance_role.name
}

# The instance role
resource "aws_iam_role" "cyhy_nessus_instance_role" {
  name               = format("cyhy_vulnscan_instance_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}

# Attach the CloudWatch Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment_cyhy_nessus" {
  role       = aws_iam_role.cyhy_nessus_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment_cyhy_nessus" {
  role       = aws_iam_role.cyhy_nessus_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
