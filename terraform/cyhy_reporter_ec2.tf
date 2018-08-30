# The reporter EC2 instance
data "aws_ami" "reporter" {
  filter {
    name = "name"
    values = [
      "cyhy-reporter-hvm-*-x86_64-ebs"
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

resource "aws_instance" "cyhy_reporter" {
  ami = "${data.aws_ami.reporter.id}"
  instance_type = "t2.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id = "${aws_subnet.cyhy_private_subnet.id}"
  private_ip = "${cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, local.the_reporter)}"
  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 200 : 8}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_private_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "CyHy Reporter"))}"

  # The reporter requires the CyHy database, so make this instance
  # dependent on cyhy_mongo
  depends_on = ["aws_instance.cyhy_mongo"]
}

# Provision the reporter EC2 instance via Ansible
module "cyhy_reporter_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.cyhy_reporter.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_reporter",
    # We want to force ansible to rerun when the instance id recreated
    "instance_arn=${aws_instance.cyhy_reporter.arn}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}
