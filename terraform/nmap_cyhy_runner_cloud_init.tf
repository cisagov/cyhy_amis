# cloud-init commands for configuring ssh and cyhy-runner

data "template_file" "nmap_disk_setup" {
  template = file("${path.module}/scripts/disk_setup.sh")

  vars = {
    num_disks     = 2
    device_name   = "/dev/xvdb"
    mount_point   = "/var/cyhy/runner"
    label         = "cyhy_runner"
    fs_type       = "ext4"
    mount_options = "defaults"
  }
}

data "template_cloudinit_config" "ssh_and_nmap_cyhy_runner_cloud_init_tasks" {
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
    content      = data.template_file.nmap_disk_setup.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.set_hostname.rendered
  }
}
