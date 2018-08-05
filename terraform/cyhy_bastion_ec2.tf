# The bastion EC2 instance
resource "aws_instance" "cyhy_bastion" {
  ami = "${data.aws_ami.bastion.id}"
  instance_type = "t2.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "CyHy Bastion"))}"
}

# Provision the bastion EC2 instance via Ansible
# module "cyhy_bastion_ansible_provisioner" {
#   source = "github.com/cloudposse/tf_ansible"

#   arguments = [
#     "--user=${var.remote_ssh_user}",
#     "--ssh-common-args='-o StrictHostKeyChecking=no'"
#   ]
#   envs = [
#     "host=${aws_instance.cyhy_bastion.public_ip}",
#     "host_groups=mongo"
#   ]
#   playbook = "../ansible/playbook.yml"
#   dry_run = false
# }
