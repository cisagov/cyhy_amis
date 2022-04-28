# cloud-init commands for setting the hostname

data "cloudinit_config" "mgmt_bastion_cloud_init_tasks" {
  count = var.enable_mgmt_vpc ? 1 : 0

  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "bastion.${aws_route53_zone.mgmt_private_zone[0].name}"
      hostname = "bastion"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
