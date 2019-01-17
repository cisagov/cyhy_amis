# cloud-init commands for configuring ssh and mongo

data "template_file" "mongo_disk_setup" {
  template = "${file("scripts/mongo_disk_setup.yml")}"

  vars {
    mongo_disk_data = "${var.mongo_disks["data"]}"
    mongo_disk_journal = "${var.mongo_disks["journal"]}"
    mongo_disk_log = "${var.mongo_disks["log"]}"
  }
}

data "template_cloudinit_config" "ssh_and_mongo_cloud_init_tasks" {
  gzip = true
  base64_encode = true

  part {
    filename     = "mongo_disk_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.mongo_disk_setup.rendered}"
  }

  part {
    filename     = "user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_ssh_setup.rendered}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    filename     = "cyhy_user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cyhy_user_ssh_setup.rendered}"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
