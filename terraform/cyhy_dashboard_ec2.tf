# The docker AMI
data "aws_ami" "dashboard" {
  filter {
    name = "name"
    values = [
      "cyhy-dashboard-hvm-*-x86_64-ebs"
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

# The cyhy dashboard EC2 instance
resource "aws_instance" "cyhy_dashboard" {
  ami = "${data.aws_ami.dashboard.id}"
  instance_type = "${local.production_workspace ? "t3.medium" : "t3.medium"}"
  # This is the private subnet
  subnet_id = "${aws_subnet.cyhy_private_subnet.id}"
  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 100 : 10}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_private_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "CyHy Dashboard"))}"
  volume_tags = "${merge(var.tags, map("Name", "CyHy Dashboard"))}"
}

# Provision the Docker EC2 instance via Ansible
module "cyhy_dashboard_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_dashboard.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_dashboard"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
