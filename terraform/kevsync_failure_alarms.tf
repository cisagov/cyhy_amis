# Create a log metric filter that bumps a metric when a syslog
# message indicates a failure in the KEV sync cron job.
resource "aws_cloudwatch_log_metric_filter" "kevsync_failure" {
  for_each = local.db_instances

  name    = "KEV Sync Failure Count - ${each.value.hostname}"
  pattern = "cyhy-kevsync ERROR"
  # The instances' CloudWatch Agent's configurations define what the
  # log group name looks like.
  log_group_name = "/instance-logs/${each.value.hostname}/syslog"

  metric_transformation {
    name      = "kevsync_failure_count_${each.value.hostname}"
    namespace = "DataIngestion"
    value     = 1
  }
}

# Alarm each time syslog indicates a failure in the KEV sync cron job.
resource "aws_cloudwatch_metric_alarm" "kevsync_failure" {
  for_each = aws_cloudwatch_log_metric_filter.kevsync_failure

  alarm_actions             = [aws_sns_topic.kevsync_failure_alarm.arn, aws_sns_topic.cloudwatch_alarm.arn]
  alarm_description         = "Monitor KEV sync failures"
  alarm_name                = "kevsync_failure_${each.value.hostname}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  insufficient_data_actions = [aws_sns_topic.cloudwatch_alarm.arn]
  metric_query {
    id          = "kevsync_failure_rate_${each.value.hostname}"
    expression  = "RATE(kevsync_failure_count_${each.value.hostname})"
    label       = "KEV Sync Failure Rate of Change - ${each.value.hostname}"
    return_data = true
  }
  metric_query {
    id = "kevsync_failure_count_${each.value.hostname}"
    metric {
      dimensions = {
        InstanceId = each.value
      }
      metric_name = "kevsync_failure_count_${each.value.hostname}"
      namespace   = "DataIngestion"
      period      = 60
      stat        = "Maximum"
    }
  }
  ok_actions = [aws_sns_topic.cloudwatch_alarm.arn, ]
  threshold  = 0
}
