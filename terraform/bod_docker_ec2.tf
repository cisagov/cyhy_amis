# The docker AMI
data "aws_ami" "bod_docker" {
  filter {
    name = "name"
    values = [
      "cyhy-docker-hvm-*-x86_64-ebs"
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

# IAM assume role policy document for the BOD Docker IAM role to be
# used by the BOD Docker EC2 instance
data "aws_iam_policy_document" "bod_docker_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The BOD Docker IAM role to be used by the BOD Docker EC2 instance
resource "aws_iam_role" "bod_docker_role" {
  assume_role_policy = "${data.aws_iam_policy_document.bod_docker_assume_role_doc.json}"
}

# IAM policy document that that allows the invocation of our Lambda
# functions.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "lambda_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    # I should be able to use splat syntax here
    resources = [
      "${aws_lambda_function.lambdas.0.arn}",
      "${aws_lambda_function.lambdas.1.arn}",
      "${aws_lambda_function.lambdas.2.arn}"
    ]
  }
}

# The Lambda policy for our role
resource "aws_iam_role_policy" "lambda_bod_docker_policy" {
  role = "${aws_iam_role.bod_docker_role.id}"
  policy = "${data.aws_iam_policy_document.lambda_bod_docker_doc.json}"
}

# IAM policy document that only allows GETting from the dmarc-import
# Elasticsearch database.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "es_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "es:ESHttpGet"
    ]

    resources = [
      "${var.dmarc_import_es_arn}",
      "${var.dmarc_import_es_arn}/*"
    ]
  }
}

# The Elasticsearch policy for our role
resource "aws_iam_role_policy" "es_bod_docker_policy" {
  role = "${aws_iam_role.bod_docker_role.id}"
  policy = "${data.aws_iam_policy_document.es_bod_docker_doc.json}"
}

# The instance profile to be used by any EC2 instances that need to
# invoke our Lambda functions and/or read the dmarc-import ES database
resource "aws_iam_instance_profile" "bod_docker" {
  role = "${aws_iam_role.bod_docker_role.name}"
}

# The docker EC2 instance
resource "aws_instance" "bod_docker" {
  ami = "${data.aws_ami.bod_docker.id}"
  instance_type = "${local.production_workspace ? "r4.xlarge" : "t2.micro"}"
  ebs_optimized = "${local.production_workspace}"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id = "${aws_subnet.bod_docker_subnet.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 200
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.bod_docker_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_and_docker_cloud_init_tasks.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.bod_docker.name}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Docker host"))}"
  volume_tags = "${merge(var.tags, map("Name", "BOD 18-01 Docker host"))}"
}

# Provision the Docker EC2 instance via Ansible
module "bod_docker_ansible_provisioner" {
  source = "github.com/cloudposse/tf_ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.bod_bastion.public_ip}\"'"
  ]
  envs = [
    "host=${aws_instance.bod_docker.private_ip}",
    "bastion_host=${aws_instance.bod_bastion.public_ip}",
    "host_groups=docker,bod_docker",
    "mongo_host=${aws_instance.cyhy_mongo.private_ip}",
    "production_workspace=${local.production_workspace}",
    "aws_region=${var.aws_region}",
    "dmarc_import_aws_region=${var.dmarc_import_aws_region}"
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
resource "aws_ebs_volume" "bod_report_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = "${local.production_workspace ? 200 : 5}"
  iops = 100
  encrypted = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "bod_report_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id = "${aws_ebs_volume.bod_report_data.id}"
  instance_id = "${aws_instance.bod_docker.id}"

  # Terraform attempts to destroy the volume attachments before it
  # attempts to destroy the EC2 instance they are attached to.  EC2
  # does not like that and it results in the failed destruction of the
  # volume attachments.  To get around this, we explicitly terminate
  # the bod_report volume via the AWS CLI in a destroy provisioner;
  # this gracefully shuts down the instance and allows terraform to
  # successfully destroy the volume attachments.
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.bod_docker.id}"
    on_failure = "continue"
  }

  # Wait until bod_report instance is terminated before continuing on
  provisioner "local-exec" {
    when = "destroy"
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.bod_docker.id}"
  }

  skip_destroy = true
}
