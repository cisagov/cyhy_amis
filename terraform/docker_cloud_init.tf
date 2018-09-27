# cloud-init commands for configuring ssh and cyhy reporter

data "template_file" "docker_disk_setup" {
  template = "${file("scripts/docker_disk_setup.yml")}"
}

data "template_cloudinit_config" "ssh_and_docker_cloud_init_tasks" {
  gzip = true
  base64_encode = true

  part {
    filename     = "docker_disk_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.docker_disk_setup.rendered}"
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
