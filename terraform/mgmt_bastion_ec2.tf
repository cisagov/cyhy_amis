# The bastion EC2 instance
resource "aws_instance" "mgmt_bastion" {
  ami = "${data.aws_ami.bastion.id}"
  instance_type = "t3.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id = "${aws_subnet.mgmt_public_subnet.id}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.mgmt_bastion_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "Management Bastion"))}"
  volume_tags = "${merge(var.tags, map("Name", "Management Bastion"))}"
}

# Provision the bastion EC2 instance via Ansible
module "mgmt_bastion_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no'"
  ]
  envs = [
    "host=${aws_instance.mgmt_bastion.public_ip}",
    "host_groups=mgmt_bastion"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
