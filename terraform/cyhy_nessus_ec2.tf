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
  instance_type = "${local.production_workspace ? "m4.2xlarge" : "m4.large"}"
  count = "${local.nessus_instance_count}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = "${aws_subnet.cyhy_vulnscanner_subnet.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${local.production_workspace ? 100 : 16}"
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.cyhy_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_and_nessus_cyhy_runner_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", format("CyHy Nessus - vulnscan%d", count.index+1), "Publish Egress", "True"))}"
  volume_tags = "${merge(var.tags, map("Name", format("CyHy Nessus - vulnscan%d", count.index+1)))}"

  # If the instance is destroyed we will have to reset the license to nessus
  lifecycle {
    prevent_destroy = true
  }
}

# The Elastic IPs for the *production* CyHy Nessus instances.  These
# EIPs can be created via dhs-ncats/elastic-ips-terraform or manually,
# and are intended to be a public IP address that rarely changes.
data "aws_eip" "cyhy_nessus_eips" {
  count = "${local.production_workspace ? local.nessus_instance_count : 0}"
  public_ip = "${cidrhost(var.cyhy_elastic_ip_cidr_block, var.cyhy_vulnscan_first_elastic_ip_offset + count.index)}"
}

# The Elastic IP for the *non-production* CyHy Nessus instances.
# These EIPs are only created in *non-production* workspaces and are
# randomly-assigned public IP address for temporary use.
resource "aws_eip" "cyhy_nessus_random_eips" {
  count = "${local.production_workspace ? 0 : local.nessus_instance_count}"
  vpc = true
  tags = "${merge(var.tags, map("Name", format("CyHy Nessus EIP %d", count.index+1), "Publish Egress", "True"))}"
}

# Associate the appropriate Elastic IPs above with the CyHy Nessus
# instances.  Since our elastic IPs are handled differently in
# production vs. non-production workspaces, their corresponding
# terraform resources (data.aws_eip.cyhy_nessus_eips,
# data.aws_eip.cyhy_nessus_random_eips) may or may not be created.  To
# handle that, we use "splat syntax" (the *), which resolves to either
# an empty list (if the resource is not present in the current
# workspace) or a valid list (if the resource is present).  Then we
# use coalescelist() to choose the (non-empty) list containing the
# valid eip.id. Finally, we use element() to choose the appropriate
# element in that non-empty list, which is the allocation_id of our
# elastic IP.  See
# https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# VOTED WORST LINE OF TERRAFORM 2018 (so far) BY DEV TEAM WEEKLY!!
resource "aws_eip_association" "cyhy_nessus_eip_assocs" {
  count = "${local.nessus_instance_count}"
  instance_id = "${element(aws_instance.cyhy_nessus.*.id, count.index)}"
  allocation_id = "${element(coalescelist(data.aws_eip.cyhy_nessus_eips.*.id, aws_eip.cyhy_nessus_random_eips.*.id), count.index)}"
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
resource "aws_ebs_volume" "nessus_cyhy_runner_data" {
  count = "${local.nessus_instance_count}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  type = "gp2"
  size = "${local.production_workspace ? 2 : 1}"
  encrypted = true

  tags = "${merge(var.tags, map("Name", format("CyHy Nessus - vulnscan%d", count.index+1)))}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "nessus_cyhy_runner_data_attachment" {
  count = "${local.nessus_instance_count}"
  device_name = "/dev/xvdb"
  volume_id = "${aws_ebs_volume.nessus_cyhy_runner_data.*.id[count.index]}"
  instance_id = "${aws_instance.cyhy_nessus.*.id[count.index]}"

  # Terraform attempts to destroy the volume attachment before it attempts to
  # destroy the EC2 instance it is attached to.  EC2 does not like that and it
  # results in the failed destruction of the volume attachment.  To get around
  # this, we explicitly terminate the cyhy_nessus instance via the AWS CLI
  # in a destroy provisioner; this gracefully shuts down the instance and
  # allows terraform to successfully destroy the volume attachments.
  provisioner "local-exec" {
    when = "destroy"
    # Use element(aws_instance.cyhy_nessus.*.id, count.index) rather than
    # aws_instance.cyhy_nessus.*.id[count.index] to avoid Terraform 'index out
    # of range' error, similar to the one documented here:
    # https://github.com/hashicorp/terraform/issues/14536#issue-228958605
    command = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${element(aws_instance.cyhy_nessus.*.id, count.index)}"
    on_failure = "continue"
  }

  # Wait until cyhy_nessus instance is terminated before continuing on
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${element(aws_instance.cyhy_nessus.*.id, count.index)}"
  }

  skip_destroy = true
  depends_on = ["aws_ebs_volume.nessus_cyhy_runner_data"]
}

# load in the dynamically created provisioner modules
module "dyn_nessus" {
  source = "./dyn_nessus"
  bastion_public_ip = "${aws_instance.cyhy_bastion.public_ip}"
  nessus_private_ips = "${aws_instance.cyhy_nessus.*.private_ip}"
  nessus_activation_codes = "${var.nessus_activation_codes}"
  remote_ssh_user = "${var.remote_ssh_user}"
}
