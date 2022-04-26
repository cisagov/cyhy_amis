# cloud-init commands for setting the hostname of an instance

data "template_file" "set_hostname" {
  template = file("${path.module}/cloud-init/set_hostname.tpl.sh")
}

data "template_cloudinit_config" "set_hostname_cloud_init_tasks" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.set_hostname.rendered
  }
}
