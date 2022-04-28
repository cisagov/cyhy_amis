# cloud-init commands for setting the hostname

data "cloudinit_config" "mgmt_nessus_cloud_init_tasks" {
  count = var.enable_mgmt_vpc ? var.mgmt_nessus_instance_count : 0

  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "vulnscan${count.index + 1}.${aws_route53_zone.mgmt_private_zone[0].name}"
      hostname = "vulnscan${count.index + 1}"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
