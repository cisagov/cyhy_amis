# ------------------------------------------------------------------------------
# Create the SNS topic that allows email to be sent for CloudWatch
# alarms.
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarm" {
  name         = format("cloudwatch-alarms_%s", local.production_workspace ? "production" : terraform.workspace)
  display_name = "cloudwatch_alarms"
}

resource "aws_sns_topic_subscription" "account_email" {
  for_each = toset(var.cloudwatch_alarm_emails)

  endpoint  = each.value
  protocol  = "email"
  topic_arn = aws_sns_topic.cloudwatch_alarm.arn
}
