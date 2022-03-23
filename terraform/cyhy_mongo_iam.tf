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

# The cyhy-archive S3 policy for our role
resource "aws_iam_role_policy" "archive_cyhy_mongo_policy" {
  role   = aws_iam_role.cyhy_mongo_instance_role.id
  policy = data.aws_iam_policy_document.s3_cyhy_archive_write_doc.json
}

# IAM policy document that allows us to assume a role that allows
# reading of the dmarc-import Elasticsearch database.  This will be
# applied to the role we are creating.
data "aws_iam_policy_document" "es_cyhy_mongo_doc" {
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
resource "aws_iam_role_policy" "es_cyhy_mongo_policy" {
  role   = aws_iam_role.cyhy_mongo_instance_role.id
  policy = data.aws_iam_policy_document.es_cyhy_mongo_doc.json
}

# IAM policy document that that allows write permissions on the MOE
# bucket.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "s3_cyhy_mongo_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.moe_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.moe_bucket.arn}/*",
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "s3_cyhy_mongo_policy" {
  role   = aws_iam_role.cyhy_mongo_instance_role.id
  policy = data.aws_iam_policy_document.s3_cyhy_mongo_doc.json
}
