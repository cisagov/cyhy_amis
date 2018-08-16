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
  instance_type = "t2.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

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

  user_data = "${data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "CyHy Nmap"))}"
  volume_tags = "${merge(var.tags, map("Name", "CyHy Nmap"))}"
}

# Provision the nmap EC2 instance via Ansible
module "cyhy_nmap_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_nmap.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
