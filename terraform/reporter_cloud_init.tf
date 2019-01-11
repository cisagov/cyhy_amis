# cloud-init commands for configuring ssh and cyhy reporter

data "template_file" "reporter_disk_setup" {
  template = "${file("scripts/reporter_disk_setup.yml")}"
}

data "template_cloudinit_config" "ssh_and_reporter_cloud_init_tasks" {
  gzip = true
  base64_encode = true

  part {
    filename     = "reporter_disk_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.reporter_disk_setup.rendered}"
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
