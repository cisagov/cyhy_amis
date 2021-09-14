# The reporter EC2 instance
data "aws_ami" "reporter" {
  filter {
    name = "name"
    values = [
      "cyhy-reporter-hvm-*-x86_64-ebs",
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

# IAM assume role policy document for the CyHy reporter IAM role to be
# used by the CyHy reporter EC2 instance
data "aws_iam_policy_document" "cyhy_reporter_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The CyHy reporter IAM role to be used by the CyHy reporter EC2
# instance
resource "aws_iam_role" "cyhy_reporter_role" {
  assume_role_policy = data.aws_iam_policy_document.cyhy_reporter_assume_role_doc.json
}

# IAM policy document that allows us to assume a role that allows
# sending of emails via SES.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "ses_cyhy_reporter_doc" {
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
resource "aws_iam_role_policy" "ses_cyhy_reporter_policy" {
  role   = aws_iam_role.cyhy_reporter_role.id
  policy = data.aws_iam_policy_document.ses_cyhy_reporter_doc.json
}

# The instance profile to be used by any EC2 instances that need to
# send emails via SES.
resource "aws_iam_instance_profile" "cyhy_reporter" {
  role = aws_iam_role.cyhy_reporter_role.name
}

resource "aws_instance" "cyhy_reporter" {
  ami               = data.aws_ami.reporter.id
  instance_type     = local.production_workspace ? "c5.2xlarge" : "t3.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  user_data_base64     = data.template_cloudinit_config.ssh_and_reporter_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_reporter.name

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Reporter"
    },
  )
  volume_tags = merge(
    var.tags,
    {
      "Name" = "CyHy Reporter"
    },
  )
}

# Provision the reporter EC2 instance via Ansible
module "cyhy_reporter_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'",
  ]
  envs = [
    "host=${aws_instance.cyhy_reporter.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=docker,cyhy_reporter",
    "production_workspace=${local.production_workspace}",
    "ses_aws_region=${var.ses_aws_region}",
    "docker_compose_override_file_for_mailer=${var.reporter_mailer_override_filename}",
    "ses_send_email_role=${var.ses_role_arn}",
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
resource "aws_ebs_volume" "cyhy_reporter_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io1"
  size              = local.production_workspace ? 500 : 5
  iops              = 100
  encrypted         = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "cyhy_reporter_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.cyhy_reporter_data.id
  instance_id = aws_instance.cyhy_reporter.id

  skip_destroy = true
}
