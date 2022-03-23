# Create the IAM instance profile for the CyHy Bastion EC2 server instance

# The instance profile to be used
resource "aws_iam_instance_profile" "cyhy_bastion" {
  name = format("cyhy_bastion_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.cyhy_bastion_instance_role.name
}

# The instance role
resource "aws_iam_role" "cyhy_bastion_instance_role" {
  name               = format("cyhy_bastion_instance_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}
