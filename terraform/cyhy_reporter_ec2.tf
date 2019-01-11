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
  instance_type = "${local.production_workspace ? "c5.2xlarge" : "t3.micro"}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id = "${aws_subnet.cyhy_private_subnet.id}"
  associate_public_ip_address = false

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_private_sg.id}"
  ]

  user_data_base64 = "${data.template_cloudinit_config.ssh_and_reporter_cloud_init_tasks.rendered}"

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
    "host_groups=docker,cyhy_reporter",
    "mongo_host=${aws_instance.cyhy_mongo.private_ip}",
    "production_workspace=${local.production_workspace}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run = false
}

# Note that the EBS volumes contain production data. Therefore we need
# these resources to be immortal in the "production" workspace, and so
# I am using the prevent_destroy lifecycle element to disallow the
# destruction of it via terraform in that case.
#
# I'd like to use "${terraform.workspace == "production" ? true :
# false}", so the prevent_destroy only applies to the production
# workspace, but it appears that interpolations are not supported
# inside of the lifecycle block
# (https://github.com/hashicorp/terraform/issues/3116).
resource "aws_ebs_volume" "cyhy_reporter_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = "${local.production_workspace ? 200 : 5}"
  iops = 100
  encrypted = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "cyhy_reporter_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id = "${aws_ebs_volume.cyhy_reporter_data.id}"
  instance_id = "${aws_instance.cyhy_reporter.id}"

  # Terraform attempts to destroy the volume attachments before it
  # attempts to destroy the EC2 instance they are attached to.  EC2
  # does not like that and it results in the failed destruction of the
  # volume attachments.  To get around this, we explicitly terminate
  # the cyhy_reporter volume via the AWS CLI in a destroy provisioner;
  # this gracefully shuts down the instance and allows terraform to
  # successfully destroy the volume attachments.
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.cyhy_reporter.id}"
    on_failure = "continue"
  }

  # Wait until cyhy_reporter instance is terminated before continuing on
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.cyhy_reporter.id}"
  }

  skip_destroy = true
}
