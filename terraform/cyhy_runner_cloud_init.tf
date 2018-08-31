# cloud-init commands for configuring ssh and cyhy-runner

data "template_file" "cyhy_runner_disk_setup" {
  template = "${file("scripts/cyhy_runner_disk_setup.yml")}"

  vars {
    cyhy_runner_disk = "${var.cyhy_runner_disk}"
  }
}

data "template_cloudinit_config" "ssh_and_cyhy_runner_cloud_init_tasks" {
  gzip = false
  base64_encode = false

  part {
    filename     = "cyhy_runner_disk_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cyhy_runner_disk_setup.rendered}"
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
