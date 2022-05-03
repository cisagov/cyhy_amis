# cloud-init commands for configuring the cyhy user, setting up the BOD 18-01
# reports volume, and setting the hostname

data "cloudinit_config" "bod_docker_cloud_init_tasks" {
  base64_encode = true
  gzip          = true

  part {
    content      = file("${path.module}/cloud-init/cyhy_user_ssh_setup.yml")
    content_type = "text/cloud-config"
    filename     = "cyhy_user_ssh_setup.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name   = "/dev/xvdb"
      fs_type       = "xfs"
      label         = "report_data"
      mount_options = "defaults"
      mount_point   = "/var/cyhy/orchestrator/output"
      num_disks     = 3
    })
    content_type = "text/x-shellscript"
    filename     = "orchestrator_disk_setup.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name   = "/dev/xvdc"
      fs_type       = "xfs"
      label         = "vdp_data"
      mount_options = "defaults"
      mount_point   = "/var/cyhy/vdp/output"
      num_disks     = 3
    })
    content_type = "text/x-shellscript"
    filename     = "vdp_disk_setup.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = true
      owner          = "cyhy"
      path           = "/var/cyhy/orchestrator/output"
    })
    content_type = "text/x-shellscript"
    filename     = "cyhy_docker_chown_orchestrator_output_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = true
      owner          = "cyhy"
      path           = "/var/cyhy/vdp/output"
    })
    content_type = "text/x-shellscript"
    filename     = "cyhy_docker_chown_vdp_output_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = false
      owner          = "cyhy"
      path           = "/var/cyhy"
    })
    content_type = "text/x-shellscript"
    filename     = "cyhy_docker_chown_cyhy_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "docker.${aws_route53_zone.bod_private_zone.name}"
      hostname = "docker"
    })
    content_type = "text/cloud-config"
    filename     = "set_hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
