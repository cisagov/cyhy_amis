# cloud-init commands

data "template_file" "mongo_disk_setup" {
  template = "${file("scripts/mongo_disk_setup.yml")}"

  vars {
    mongo_disk_data = "${var.mongo_disks["data"]}"
    mongo_disk_journal = "${var.mongo_disks["journal"]}"
    mongo_disk_log = "${var.mongo_disks["log"]}"
  }
}

data "template_file" "user_ssh_setup" {
  template = "${file("scripts/user_ssh_setup.yml")}"
}

data "template_cloudinit_config" "cloud_init_tasks" {
  gzip = false
  base64_encode = false

  part {
    filename     = "mongo_disk_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.mongo_disk_setup.rendered}"
  }

  part {
    filename     = "user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_ssh_setup.rendered}"
  }
}
