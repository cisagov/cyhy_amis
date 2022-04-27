# cloud-init commands for configuring the cyhy user and setting the hostname

data "cloudinit_config" "cyhy_dashboard_cloud_init_tasks" {
  base64_encode = true
  gzip          = true

  part {
    content      = file("${path.module}/cloud-init/cyhy_user_ssh_setup.tpl.yml")
    content_type = "text/cloud-config"
    filename     = "cyhy_user_ssh_setup.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

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
}