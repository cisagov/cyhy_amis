data "aws_ami" "nmap" {
  filter {
    name = "name"
    values = [
      "cyhy-nmap-hvm-*-x86_64-ebs"
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

resource "aws_instance" "cyhy_nmap" {
  ami = "${data.aws_ami.nmap.id}"
  instance_type = "${local.production_workspace ? "t2.medium" : "t2.micro"}"
  count = "${local.nmap_instance_count}"

  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"
  private_ip = "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, count.index + local.first_port_scanner)}"

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 50 : 8}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "CyHy Nmap"))}"
  volume_tags = "${merge(var.tags, map("Name", "CyHy Nmap"))}"
}

# TODO: until we figure out how to loop a module, a copy needs to be made for
# each instance.  This also prevents us from differentiating production from
# development.
# Provision the nmap EC2 instances via Ansible
module "cyhy_nmap_ansible_provisioner_0" {
  source = "github.com/cloudposse/tf_ansible"
  #count = "${local.nmap_instance_count}"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.0.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

# module "cyhy_nmap_ansible_provisioner_1" {
#   source = "github.com/cloudposse/tf_ansible"
#   #count = "${local.nmap_instance_count}"
#
#   arguments = [
#     "--user=${var.remote_ssh_user}",
#     "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
#   ]
#   envs = [
#     "host=${aws_instance.cyhy_nmap.1.private_ip}",
#     "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
#     "host_groups=cyhy_runner"
#   ]
#   playbook = "../ansible/playbook.yml"
#   dry_run = false
# }
