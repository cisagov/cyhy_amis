resource "aws_instance" "mgmt_nessus" {
  ami = "${data.aws_ami.nessus.id}"
  instance_type = "m4.large"
  ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = "${aws_subnet.mgmt_private_subnet.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 100 : 16}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.mgmt_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "Management Nessus - vulnscan1"))}"
  volume_tags = "${merge(var.tags, map("Name", "Management Nessus - vulnscan1"))}"

  # If the instance is destroyed we will have to reset the license to nessus
  lifecycle {
    prevent_destroy = true
  }
}

# Provision a Nessus EC2 instance via Ansible
module "mgmt_nessus_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.mgmt_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.mgmt_nessus.private_ip}",
    "bastion_host=${aws_instance.mgmt_bastion.public_ip}",
    "host_groups=nessus",
    "nessus_activation_code=${var.mgmt_nessus_activation_code}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
