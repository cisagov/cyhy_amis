# cloud-init commands for configuring the cyhy user and setting the hostname

data "cloudinit_config" "cyhy_dashboard_cloud_init_tasks" {
  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "dashboard.${aws_route53_zone.cyhy_private_zone.name}"
      hostname = "dashboard"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = var.cyhy_user_info.name
      is_mount_point = false
      owner          = var.cyhy_user_info.name
      path           = var.cyhy_user_info.home
    })
    content_type = "text/x-shellscript"
    filename     = "00_cyhy_dashboard_chown_cyhy_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = var.cyhy_user_info.name
      is_mount_point = false
      owner          = var.cyhy_user_info.name
      path           = "/var/log/cyhy"
    })
    content_type = "text/x-shellscript"
    filename     = "00_cyhy_dashboard_chown_cyhy_log_directory.sh"
  }
}
