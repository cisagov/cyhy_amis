# cloud-init commands for setting up the cyhy user, setting up the cyhy-reports
# volume, and setting the hostname

data "cloudinit_config" "cyhy_reporter_cloud_init_tasks" {
  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "reporter.${aws_route53_zone.cyhy_private_zone.name}"
      hostname = "reporter"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content = templatefile("${path.module}/cloud-init/configure_cloudwatch_agent.tpl.yml", {
      cloudwatch_agent_log_group_base_name = local.cyhy_cloudwatch_agent_log_group_base
    })
    content_type = "text/cloud-config"
    filename     = "configure_cloudwatch_agent.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = false
      owner          = "cyhy"
      path           = "/var/cyhy"
    })
    content_type = "text/x-shellscript"
    filename     = "00_cyhy_reports_chown_cyhy_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = false
      owner          = "cyhy"
      path           = "/var/log/cyhy"
    })
    content_type = "text/x-shellscript"
    filename     = "00_cyhy_reports_chown_cyhy_log_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name   = "/dev/xvdb"
      fs_type       = "xfs"
      label         = "report_data"
      mount_options = "defaults"
      mount_point   = "/var/cyhy/reports/output"
      num_disks     = 2
    })
    content_type = "text/x-shellscript"
    filename     = "01_cyhy_reports_disk_setup.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = true
      owner          = "cyhy"
      path           = "/var/cyhy/reports/output"
    })
    content_type = "text/x-shellscript"
    filename     = "02_cyhy_reports_chown_reports_output_directory.sh"
  }
}
