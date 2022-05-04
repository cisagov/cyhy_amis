# Create the IAM instance profile for the CyHy Database EC2 server instances

# The instance profile to be used
resource "aws_iam_instance_profile" "cyhy_mongo" {
  name = format("cyhy_database_instance_profile_%s", local.production_workspace ? "production" : terraform.workspace)
  role = aws_iam_role.cyhy_mongo_instance_role.name
}

# The instance role
resource "aws_iam_role" "cyhy_mongo_instance_role" {
  name               = format("cyhy_database_instance_role_%s", local.production_workspace ? "production" : terraform.workspace)
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume_role_doc.json
}

# Attach the CloudWatch Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment_cyhy_mongo" {
  role       = aws_iam_role.cyhy_mongo_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach the SSM Agent policy to this role as well
resource "aws_iam_role_policy_attachment" "ssm_agent_policy_attachment_cyhy_mongo" {
  role       = aws_iam_role.cyhy_mongo_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the dmarc-import Elasticsearch assume role policy to this role as well
resource "aws_iam_role_policy_attachment" "dmarc_es_assume_role_policy_attachment_cyhy_mongo" {
  role       = aws_iam_role.cyhy_mongo_instance_role.id
  policy_arn = aws_iam_policy.dmarc_es_assume_role_policy.arn
}

# Attach the cyhy-archive S3 write policy to this role as well
resource "aws_iam_role_policy_attachment" "s3_cyhy_archive_write_policy_attachment_cyhy_mongo" {
  role       = aws_iam_role.cyhy_mongo_instance_role.id
  policy_arn = aws_iam_policy.s3_cyhy_archive_write_policy.arn
}

# Attach the MOE S3 bucket write policy to this role as well
resource "aws_iam_role_policy_attachment" "moe_bucket_write_policy_attachment_cyhy_mongo" {
  role       = aws_iam_role.cyhy_mongo_instance_role.id
  policy_arn = aws_iam_policy.moe_bucket_write.arn
}
