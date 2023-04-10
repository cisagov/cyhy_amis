# ------------------------------------------------------------------------------
# Create the SNS topic that allows email to be sent when the findings-data-import
# Lambda has a failure when processing an uploaded JSON.
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "fdi_failure_alarm" {
  name         = format("fdi-failure-alarms_%s", local.production_workspace ? "production" : terraform.workspace)
  display_name = "findings-data-import_failure_alarm"
}

# Allow the findings data bucket (and only the findings data bucket) to publish
# notifications to the fdi failure alarm SNS topic.
data "aws_iam_policy_document" "fdi_failure_alarm" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    resources = [aws_sns_topic.fdi_failure_alarm.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [data.aws_s3_bucket.findings_data.arn]
    }
  }
}

resource "aws_sns_topic_policy" "fdi_failure_alarm" {
  arn    = aws_sns_topic.fdi_failure_alarm.arn
  policy = data.aws_iam_policy_document.fdi_failure_alarm.json
}

resource "aws_sns_topic_subscription" "fdi_failure_alarm" {
  for_each = toset(var.findings_data_import_lambda_failure_emails)

  endpoint  = each.value
  protocol  = "email"
  topic_arn = aws_sns_topic.fdi_failure_alarm.arn
}
