# cloud-init commands for configuring ssh and mongo

data "template_file" "mongo_data_disk_setup" {
  template = file("${path.module}/scripts/disk_setup.sh")

  vars = {
    num_disks     = 4
    device_name   = var.mongo_disks["data"]
    mount_point   = "/var/lib/mongodb"
    label         = "mongo_data"
    fs_type       = "xfs"
    mount_options = "defaults"
  }
}

data "template_file" "mongo_journal_disk_setup" {
  template = file("${path.module}/scripts/disk_setup.sh")

  vars = {
    num_disks   = 4
    device_name = var.mongo_disks["journal"]
    mount_point = "/var/lib/mongodb/journal"
    label       = "mongo_journal"
    fs_type     = "ext4"
    # The x-systemd.requires bit forces the Mongo data disk to be
    # mounted before this one
    mount_options = "defaults,x-systemd.requires=/var/lib/mongodb"
  }
}

data "template_file" "mongo_log_disk_setup" {
  template = file("${path.module}/scripts/disk_setup.sh")

  vars = {
    num_disks     = 4
    device_name   = var.mongo_disks["log"]
    mount_point   = "/var/log/mongodb"
    label         = "mongo_log"
    fs_type       = "ext4"
    mount_options = "defaults"
  }
}

data "template_file" "mongo_journal_mountpoint_setup" {
  template = file("${path.module}/scripts/mongo_journal_mountpoint_setup.sh")
}

data "template_file" "mongo_dir_setup" {
  template = file("${path.module}/scripts/mongo_dir_setup.sh")
}

data "template_cloudinit_config" "ssh_and_mongo_cloud_init_tasks" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = data.template_file.user_ssh_setup.rendered
  }

  part {
    filename     = "cyhy_user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = data.template_file.cyhy_user_ssh_setup.rendered
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mongo_data_disk_setup.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mongo_journal_mountpoint_setup.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mongo_journal_disk_setup.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mongo_log_disk_setup.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mongo_dir_setup.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.set_hostname.rendered
  }
}
