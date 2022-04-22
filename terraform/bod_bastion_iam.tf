# Create the IAM instance profile for the BOD Bastion EC2 server instance

# The instance profile to be used
resource "aws_iam_instance_profile" "bod_bastion" {
  name = format("bod_bastion_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.bod_bastion_instance_role.name
}

# The instance role
resource "aws_iam_role" "bod_bastion_instance_role" {
  name               = format("bod_bastion_instance_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}

# Attach the CloudWatch Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment_bod_bastion" {
  role       = aws_iam_role.bod_bastion_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment_bod_bastion" {
  role       = aws_iam_role.bod_bastion_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}