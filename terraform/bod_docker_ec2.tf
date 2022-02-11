# The docker AMI
data "aws_ami" "bod_docker" {
  filter {
    name = "name"
    values = [
      "cyhy-docker-hvm-*-x86_64-ebs",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners      = [data.aws_caller_identity.current.account_id] # This is us
  most_recent = true
}

# IAM assume role policy document for the BOD Docker IAM role to be
# used by the BOD Docker EC2 instance
data "aws_iam_policy_document" "bod_docker_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The BOD Docker IAM role to be used by the BOD Docker EC2 instance
resource "aws_iam_role" "bod_docker_role" {
  assume_role_policy = data.aws_iam_policy_document.bod_docker_assume_role_doc.json
}

# IAM policy document that that allows the invocation of our Lambda
# functions.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "lambda_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    # I should be able to use splat syntax here
    resources = [
      aws_lambda_function.lambdas[0].arn,
      aws_lambda_function.lambdas[1].arn,
      aws_lambda_function.lambdas[2].arn,
    ]
  }
}

# The Lambda policy for our role
resource "aws_iam_role_policy" "lambda_bod_docker_policy" {
  role   = aws_iam_role.bod_docker_role.id
  policy = data.aws_iam_policy_document.lambda_bod_docker_doc.json
}

# IAM policy document that allows us to assume a role that allows
# reading of the dmarc-import Elasticsearch database.  This will be
# applied to the role we are creating.
data "aws_iam_policy_document" "es_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      var.dmarc_import_es_role_arn,
    ]
  }
}

# The Elasticsearch policy for our role
resource "aws_iam_role_policy" "es_bod_docker_policy" {
  role   = aws_iam_role.bod_docker_role.id
  policy = data.aws_iam_policy_document.es_bod_docker_doc.json
}

# IAM policy document that allows us to assume a role that allows
# sending of emails via SES.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "ses_bod_docker_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      var.ses_role_arn,
    ]
  }
}

# The SES policy for our role
resource "aws_iam_role_policy" "ses_bod_docker_policy" {
  role   = aws_iam_role.bod_docker_role.id
  policy = data.aws_iam_policy_document.ses_bod_docker_doc.json
}

# The instance profile to be used by any EC2 instances that need to
# invoke our Lambda functions, read the dmarc-import ES database,
# and/or send emails via SES.
resource "aws_iam_instance_profile" "bod_docker" {
  role = aws_iam_role.bod_docker_role.name
}

# The docker EC2 instance
resource "aws_instance" "bod_docker" {
  ami               = data.aws_ami.bod_docker.id
  instance_type     = local.production_workspace ? "r5.xlarge" : "t3.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id = aws_subnet.bod_docker_subnet.id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 200
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.bod_docker_sg.id,
  ]

  user_data_base64     = data.template_cloudinit_config.ssh_and_docker_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.bod_docker.name

  tags = { "Name" = "BOD 18-01 Docker host" }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = "BOD 18-01 Docker host"
    },
  )
}

# Provision the Docker EC2 instance via Ansible
module "bod_docker_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.bod_bastion.public_ip}\"'",
  ]
  envs = [
    "host=${aws_instance.bod_docker.private_ip}",
    "bastion_host=${aws_instance.bod_bastion.public_ip}",
    "host_groups=docker,bod_docker",
    "production_workspace=${local.production_workspace}",
    "aws_region=${var.aws_region}",
    "dmarc_import_aws_region=${var.dmarc_import_aws_region}",
    "dmarc_import_es_role=${var.dmarc_import_es_role_arn}",
    "ses_aws_region=${var.ses_aws_region}",
    "ses_send_email_role=${var.ses_role_arn}",
    # This file will be used to add/override any settings in
    # docker-compose.yml (for cyhy-mailer).
    "docker_compose_override_file_for_mailer=${var.docker_mailer_override_filename}",
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
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
  type              = "io1"
  size              = local.production_workspace ? 200 : 5
  iops              = 100
  encrypted         = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "bod_report_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.bod_report_data.id
  instance_id = aws_instance.bod_docker.id

  skip_destroy = true
}
