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
  instance_type = "${local.production_workspace ? "t2.large" : "t2.micro"}"
  count = "${local.nmap_instance_count}"

  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"
  private_ip = "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, count.index + local.first_port_scanner)}"

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 16 : 8}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_and_cyhy_runner_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", format("CyHy Nmap - portscan%d", count.index+1), "Publish Egress", "True"))}"
  volume_tags = "${merge(var.tags, map("Name", "CyHy Nmap"))}"
}

# Note that the EBS volume contains production data. Therefore we need
# these resources to be immortal in the "production" workspace, and so
# I am using the prevent_destroy lifecycle element to disallow the
# destruction of it via terraform in that case.
#
# I'd like to use "${terraform.workspace == "production" ? true :
# false}", so the prevent_destroy only applies to the production
# workspace, but it appears that interpolations are not supported
# inside of the lifecycle block
# (https://github.com/hashicorp/terraform/issues/3116).
resource "aws_ebs_volume" "cyhy_runner_data" {
  count = "${local.nmap_instance_count}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "gp2"
  size = "${local.production_workspace ? 2 : 1}"
  encrypted = true

  tags = "${merge(var.tags, map("Name", "cyhy-runner data"))}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "cyhy_runner_data_attachment" {
  count = "${local.nmap_instance_count}"
  device_name = "${var.cyhy_runner_disk}"
  volume_id = "${aws_ebs_volume.cyhy_runner_data.id}"
  instance_id = "${aws_instance.cyhy_nmap.id}"

  # Terraform attempts to destroy the volume attachment before it attempts to
  # destroy the EC2 instance it is attached to.  EC2 does not like that and it
  # results in the failed destruction of the volume attachment.  To get around
  # this, we explicitly terminate the cyhy_runner_data volume via the AWS CLI
  # in a destroy provisioner; this gracefully shuts down the instance and
  # allows terraform to successfully destroy the volume attachments.
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.cyhy_nmap.id}"
    on_failure = "continue"
  }

  # Wait until cyhy_nmap instance is terminated before continuing on
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.cyhy_nmap.id}"
  }

  skip_destroy = true
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
