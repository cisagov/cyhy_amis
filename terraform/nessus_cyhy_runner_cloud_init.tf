# cloud-init commands for configuring ssh and cyhy-runner

data "template_file" "nessus_cyhy_runner_disk_setup" {
  template = "${file("scripts/cyhy_runner_disk_setup.yml")}"

  vars {
    cyhy_runner_disk = "${var.nessus_cyhy_runner_disk}"
  }
}

data "template_cloudinit_config" "ssh_and_nessus_cyhy_runner_cloud_init_tasks" {
  gzip = true
  base64_encode = true

  part {
    filename     = "cyhy_runner_disk_setup.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.nessus_cyhy_runner_disk_setup.rendered}"
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
