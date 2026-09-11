# Create the Trust Policy (assume role policy) for the Data Lifecycle
# Manager IAM Role
data "aws_iam_policy_document" "dlm_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

# Create the DLM IAM Role
resource "aws_iam_role" "dlm_lifecycle_role" {
  assume_role_policy = data.aws_iam_policy_document.dlm_assume_role.json
  name               = "dlm-lifecycle-role"
}

# Attach the necessary AWS-managed policy to the DLM role
resource "aws_iam_role_policy_attachment" "dlm_lifecycle_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
  role       = aws_iam_role.dlm_lifecycle_role.name
}
