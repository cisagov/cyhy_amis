# Create a log metric filter that bumps a metric when a syslog
# message indicates a failure in the NVD sync cron job.
resource "aws_cloudwatch_log_metric_filter" "nvdsync_failure" {
  for_each = local.db_instances

  name = "NVD Sync Failure Count - ${each.value.hostname}"
  # Note that this pattern relies on:
  # 1. A logging.exception() call for any uncaught exceptions in the
  #    main() method of the cyhy-nvdsync script in cisagov/cyhy-core
  # 2. The stdout and stderr of the cyhy-nvdsync script being piped
  #    into the system logger with the tag "cyhy-nvdsync" when that
  #    script is run, as is done in
  #    https://github.com/cisagov/cyhy_amis/blob/0f5974229edd909befc90ff5f4cf639327d373d8/ansible/roles/cyhy_commander/tasks/main.yml#L160
  #
  # The quotes around cyhy-nvdsync are necessary because the hyphen is
  # a special character in the log metric filter syntax:
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html
  pattern = "\"cyhy-nvdsync\" ERROR"
  # The instances' CloudWatch Agent's configurations define what the
  # log group name looks like.
  #
  # We have to account for the fact that the local hostname on the
  # instance drops the local domain name.
  log_group_name = "/instance-logs/${split(".", each.value.hostname)[0]}"

  metric_transformation {
    default_value = 0
    # See below for explanation of the following substitution.
    name      = replace("nvdsync_failure_count_${each.value.hostname}", ".", "_")
    namespace = "DataIngestion"
    value     = 1
  }
}

# Alarm each time syslog indicates a failure in the NVD sync cron job.
resource "aws_cloudwatch_metric_alarm" "nvdsync_failure" {
  for_each = local.db_instances

  alarm_actions             = [aws_sns_topic.cloudwatch_alarm.arn, ]
  alarm_description         = "Monitor NVD sync failures"
  alarm_name                = format("nvdsync_failure_%s_%s", each.value.hostname, local.production_workspace ? "production" : terraform.workspace)
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  insufficient_data_actions = [aws_sns_topic.cloudwatch_alarm.arn, ]
  metric_query {
    # Replace periods in the hostname with underscores in order to avoid
    # "ValidationError: Invalid metrics list" errors.
    id          = replace("nvdsync_failure_rate_${each.value.hostname}", ".", "_")
    expression  = replace("RATE(nvdsync_failure_count_${each.value.hostname})", ".", "_")
    label       = "NVD Sync Failure Rate of Change - ${each.value.hostname}"
    return_data = true
  }
  metric_query {
    # Replace periods in the hostname with underscores in order to avoid
    # "ValidationError: Invalid metrics list" errors.
    id = replace("nvdsync_failure_count_${each.value.hostname}", ".", "_")
    metric {
      metric_name = replace("nvdsync_failure_count_${each.value.hostname}", ".", "_")
      namespace   = "DataIngestion"
      period      = 60
      stat        = "Maximum"
    }
  }
  ok_actions = [aws_sns_topic.cloudwatch_alarm.arn, ]
  threshold  = 0
}
