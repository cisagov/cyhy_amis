# ------------------------------------------------------------------------------
# Create the SNS topic that allows email to be sent for CloudWatch
# alarms related to kevsync failures on the database instances.
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "kevsync_failure_alarm" {
  name         = "kevsync-failure-alarms"
  display_name = "kevsync_failure_alarms"
}

resource "aws_sns_topic_subscription" "kevsync_failure_email" {
  for_each = toset(var.kevsync_failure_emails)

  endpoint  = each.value
  protocol  = "email"
  topic_arn = aws_sns_topic.kevsync_failure_alarm.arn
}
