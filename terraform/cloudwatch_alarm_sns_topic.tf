# ------------------------------------------------------------------------------
# Create the SNS topic that allows email to be sent for CloudWatch
# alarms.  Subscribe the account email to the new SNS topic.
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "cloudwatch_alarm" {
  name         = "cloudwatch-alarms"
  display_name = "cloudwatch_alarms"
}

resource "aws_sns_topic_subscription" "account_email" {
  endpoint  = "cisa-cool-group+cyhy@trio.dhs.gov"
  protocol  = "email"
  topic_arn = aws_sns_topic.cloudwatch_alarm.arn
}
