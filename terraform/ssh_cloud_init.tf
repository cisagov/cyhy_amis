# cloud-init commands for configuring ssh

data "template_file" "user_ssh_setup" {
  template = "${file("scripts/user_ssh_setup.yml")}"
}

data "template_cloudinit_config" "ssh_cloud_init_tasks" {
  gzip = true
  base64_encode = true

  part {
    filename     = "user_ssh_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_ssh_setup.rendered}"
  }
}
