data "aws_ami" "nessus" {
  filter {
    name = "name"
    values = [
      "cyhy-nessus-hvm-*-x86_64-ebs"
    ]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"] # This is us
  most_recent = true
}

resource "aws_instance" "cyhy_nessus" {
  ami = "${data.aws_ami.nessus.id}"
  instance_type = "m4.large"
  count = "${local.nessus_instance_count}"
  ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"
  private_ip = "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, count.index + local.first_vuln_scanner)}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "CyHy Nessus"))}"
  volume_tags = "${merge(var.tags, map("Name", "CyHy Nessus"))}"
}

# TODO: until we figure out how to loop a module, a copy needs to be made for
# each instance.  This also prevents us from differentiating production from
# development.

# Provision the Nessus EC2 instance via Ansible
module "cyhy_nessus_ansible_provisioner_0" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nessus.0.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nessus"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

# Provision the Nessus EC2 instance via Ansible
module "cyhy_nessus_ansible_provisioner_1" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nessus.1.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nessus"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
