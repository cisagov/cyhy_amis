# cloud-init commands for configuring the cyhy user, setting up the cyhy-runner
# volume, and setting the hostname

data "cloudinit_config" "cyhy_nessus_cloud_init_tasks" {
  count = var.nessus_instance_count

  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
      hostname = "vulnscan${count.index + 1}"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
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
    filename     = "00_cyhy_nessus_chown_cyhy_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = false
      owner          = "cyhy"
      path           = "/var/log/cyhy"
    })
    content_type = "text/x-shellscript"
    filename     = "00_cyhy_nessus_chown_cyhy_log_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name   = "/dev/xvdb"
      fs_type       = "ext4"
      label         = "cyhy_runner"
      mount_options = "defaults"
      mount_point   = "/var/cyhy/runner"
      num_disks     = 2
    })
    content_type = "text/x-shellscript"
    filename     = "01_cyhy_runner_disk_setup.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = true
      owner          = "cyhy"
      path           = "/var/cyhy/runner"
    })
    content_type = "text/x-shellscript"
    filename     = "02_cyhy_nessus_chown_runner_directory.sh"
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
