# cloud-init commands for setting the hostname

data "cloudinit_config" "cyhy_bastion_cloud_init_tasks" {
  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "bastion.${aws_route53_zone.cyhy_private_zone.name}"
      hostname = "bastion"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  # Fix the DHCP options in the Canonical Netplan configuration
  # created by cloud-init.
  #
  # The issue is that Netplan uses a default of false for
  # dhcp4-overrides.use-domains, and cloud-init does not explicitly
  # set this key or provide any way to do so.
  #
  # See these issues for more details:
  # - cisagov/skeleton-packer#300
  # - canonical/cloud-init#4764
  part {
    content = templatefile(
      "${path.module}/cloud-init/fix_dhcp.tpl.py", {
        netplan_config = "/etc/netplan/50-cloud-init.yaml"
    })
    content_type = "text/x-shellscript"
    filename     = "fix_dhcp.py"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  # Now that the DHCP options in the Canonical Netplan configuration
  # created by cloud-init have been fixed, reapply the Netplan
  # configuration.
  #
  # The issue is that Netplan uses a default of false for
  # dhcp4-overrides.use-domains, and cloud-init does not explicitly
  # set this key or provide any way to do so.
  #
  # See these issues for more details:
  # - cisagov/skeleton-packer#300
  # - canonical/cloud-init#4764
  part {
    content      = file("${path.module}/cloud-init/fix_dhcp.yml")
    content_type = "text/cloud-config"
    filename     = "fix_dhcp.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
