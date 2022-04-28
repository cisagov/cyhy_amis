# Create a log metric filter that bumps a metric when a syslog
# message indicates a failure in the KEV sync cron job.
resource "aws_cloudwatch_log_metric_filter" "kevsync_failure" {
  for_each = local.db_instances

  name = "KEV Sync Failure Count - ${each.value.hostname}"
  # Note that this pattern relies on:
  # 1. A logging.exception() call for any uncaught exceptions in the
  #    main() method of the cyhy-kevsync script in cisagov/cyhy-core
  # 2. The stdout and stderr of the cyhy-kevsync script being piped
  #    into the system logger with the tag "cyhy-kevsync" when that
  #    script is run, similar to what is done for the cyhy-nvdsync script here:
  #    https://github.com/cisagov/cyhy_amis/blob/0f5974229edd909befc90ff5f4cf639327d373d8/ansible/roles/cyhy_commander/tasks/main.yml#L160
  #
  # The quotes around cyhy-kevsync are necessary because the hyphen is
  # a special character in the log metric filter syntax:
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html
  pattern = "\"cyhy-kevsync\" ERROR"
  # The instances' CloudWatch Agent's configurations define what the
  # log group name looks like.
  log_group_name = "/instance-logs/${each.value.hostname}"

  metric_transformation {
    # See below for explanation of the following substitution.
    name      = replace("kevsync_failure_count_${each.value.hostname}", ".", "_")
    namespace = "DataIngestion"
    value     = 1
  }
}

# Alarm each time syslog indicates a failure in the KEV sync cron job.
resource "aws_cloudwatch_metric_alarm" "kevsync_failure" {
  for_each = local.db_instances

  alarm_actions             = [aws_sns_topic.kevsync_failure_alarm.arn, aws_sns_topic.cloudwatch_alarm.arn]
  alarm_description         = "Monitor KEV sync failures"
  alarm_name                = format("kevsync_failure_%s_%s", each.value.hostname, local.production_workspace ? "production" : terraform.workspace)
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  insufficient_data_actions = [aws_sns_topic.cloudwatch_alarm.arn]
  metric_query {
    # Replace periods in the hostname with underscores in order to avoid
    # "ValidationError: Invalid metrics list" errors.
    id          = replace("kevsync_failure_rate_${each.value.hostname}", ".", "_")
    expression  = replace("RATE(kevsync_failure_count_${each.value.hostname})", ".", "_")
    label       = "KEV Sync Failure Rate of Change - ${each.value.hostname}"
    return_data = true
  }
  metric_query {
    # Replace periods in the hostname with underscores in order to avoid
    # "ValidationError: Invalid metrics list" errors.
    id = replace("kevsync_failure_count_${each.value.hostname}", ".", "_")
    metric {
      dimensions = {
        InstanceId = each.key
      }
      metric_name = replace("kevsync_failure_count_${each.value.hostname}", ".", "_")
      namespace   = "DataIngestion"
      period      = 60
      stat        = "Maximum"
    }
  }
  ok_actions = [aws_sns_topic.cloudwatch_alarm.arn, ]
  threshold  = 0
}
