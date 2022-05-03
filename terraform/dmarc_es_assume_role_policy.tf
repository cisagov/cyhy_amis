# IAM policy document that allows us to assume a role that allows
# reading of the dmarc-import Elasticsearch database.
data "aws_iam_policy_document" "dmarc_es_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    resources = [
      var.dmarc_import_es_role_arn,
    ]
  }
}

# Create a policy that can be attached to any role that needs to access the
# dmarc-import Elasticsearch database.
resource "aws_iam_policy" "dmarc_es_assume_role_policy" {
  name   = format("dmarc_es_assume_role_%s", local.production_workspace ? "production" : terraform.workspace)
  policy = data.aws_iam_policy_document.dmarc_es_assume_role_doc.json
}
