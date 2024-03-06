# cloud-init commands for configuring the cyhy user, configuring mongo volumes,
# and setting the hostname

data "cloudinit_config" "cyhy_mongo_cloud_init_tasks" {
  count = var.mongo_instance_count

  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/cloud-init/set_hostname.tpl.yml", {
      # Note that the hostname here is identical to what is set in
      # the corresponding DNS A record.
      fqdn     = "database${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
      hostname = "database${count.index + 1}"
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
    filename     = "00_cyhy_mongo_chown_cyhy_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/chown_directory.tpl.sh", {
      group          = "cyhy"
      is_mount_point = false
      owner          = "cyhy"
      path           = "/var/log/cyhy"
    })
    content_type = "text/x-shellscript"
    filename     = "00_cyhy_mongo_chown_cyhy_log_directory.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name   = var.mongo_disks["data"]
      fs_type       = "xfs"
      label         = "mongo_data"
      mount_options = "defaults"
      mount_point   = "/var/lib/mongodb"
      num_disks     = 4
    })
    content_type = "text/x-shellscript"
    filename     = "01_mongo_data_disk_setup.sh"
  }

  part {
    content      = file("${path.module}/cloud-init/mongo_journal_mountpoint_setup.sh")
    content_type = "text/x-shellscript"
    filename     = "02_mongo_journal_mountpoint_setup.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name = var.mongo_disks["journal"]
      fs_type     = "ext4"
      label       = "mongo_journal"
      # The x-systemd.requires bit forces the Mongo data disk to be
      # mounted before this one
      mount_options = "defaults,x-systemd.requires=/var/lib/mongodb"
      mount_point   = "/var/lib/mongodb/journal"
      num_disks     = 4
    })
    content_type = "text/x-shellscript"
    filename     = "03_mongo_journal_disk_setup.sh"
  }

  part {
    content = templatefile("${path.module}/cloud-init/disk_setup.tpl.sh", {
      device_name   = var.mongo_disks["log"]
      fs_type       = "ext4"
      label         = "mongo_log"
      mount_options = "defaults"
      mount_point   = "/var/log/mongodb"
      num_disks     = 4
    })
    content_type = "text/x-shellscript"
    filename     = "04_mongo_log_disk_setup.sh"
  }

  part {
    content      = file("${path.module}/cloud-init/mongo_dir_setup.sh")
    content_type = "text/x-shellscript"
    filename     = "05_mongo_dir_setup.sh"
  }
}
