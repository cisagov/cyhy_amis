# Create a log metric filter that bumps a metric when a syslog
# message indicates a failure in the NVD sync cron job.
resource "aws_cloudwatch_log_metric_filter" "nvdsync_failure" {
  for_each = local.db_instances

  name    = "NVD Sync Failure Count - ${each.value.hostname}"
  pattern = "cyhy-nvdsync ERROR"
  # The instances' CloudWatch Agent's configurations define what the
  # log group name looks like.
  log_group_name = "/instance-logs/${each.value.hostname}/syslog"

  metric_transformation {
    name      = "nvdsync_failure_count_${each.value.hostname}"
    namespace = "DataIngestion"
    value     = 1
  }
}

# Alarm each time syslog indicates a failure in the NVD sync cron job.
resource "aws_cloudwatch_metric_alarm" "nvdsync_failure" {
  for_each = aws_cloudwatch_log_metric_filter.nvdsync_failure

  alarm_actions             = [aws_sns_topic.cloudwatch_alarm.arn, ]
  alarm_description         = "Monitor NVD sync failures"
  alarm_name                = "nvdsync_failure_${each.value.hostname}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  insufficient_data_actions = [aws_sns_topic.cloudwatch_alarm.arn, ]
  metric_query {
    id          = "nvdsync_failure_rate_${each.value.hostname}"
    expression  = "RATE(nvdsync_failure_count_${each.value.hostname})"
    label       = "NVD Sync Failure Rate of Change - ${each.value.hostname}"
    return_data = true
  }
  metric_query {
    id = "nvdsync_failure_count_${each.value.hostname}"
    metric {
      dimensions = {
        InstanceId = each.value
      }
      metric_name = "nvdsync_failure_count_${each.value.hostname}"
      namespace   = "DataIngestion"
      period      = 60
      stat        = "Maximum"
    }
  }
  ok_actions = [aws_sns_topic.cloudwatch_alarm.arn, ]
  threshold  = 0
}
