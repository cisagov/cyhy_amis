# The reporter EC2 instance
data "aws_ami" "reporter" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefixes.reporter}-reporter-hvm-*-x86_64-ebs",
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

resource "aws_instance" "cyhy_reporter" {
  ami               = data.aws_ami.reporter.id
  instance_type     = local.production_workspace ? "c5.9xlarge" : "t3.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

  # AWS Instance Metadata Service (IMDS) options
  metadata_options {
    # Enable IMDS (this is the default value)
    http_endpoint = "enabled"
    # Normally we restrict put responses from IMDS to a single hop
    # (this is the default value).  This effectively disallows the
    # retrieval of an IMDSv2 token via this machine from anywhere
    # else.
    #
    # In this case we set the hop limit to two, since the
    # cisagov/cyhy-mailer Docker container hosted on this instance
    # needs to retrieve credentials from IMDS to send email using SES.
    http_put_response_hop_limit = 2
    # Require IMDS tokens AKA require the use of IMDSv2
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  depends_on = [
    # This volume is needed for cyhy-reports data
    aws_ebs_volume.cyhy_reporter_data,
    # Reporting needs the database available to function
    aws_instance.cyhy_mongo,
  ]

  user_data_base64     = data.cloudinit_config.cyhy_reporter_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_reporter.name

  tags = { "Name" = "CyHy Reporter" }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = "CyHy Reporter"
    },
  )
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
  type              = "io2"
  size              = local.production_workspace ? 1000 : 5
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

  stop_instance_before_detaching = true
}

# Provision the reporter EC2 instance via Ansible
module "cyhy_reporter_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"

  # Ensure any EBS volumes are attached before running Ansible
  depends_on = [
    aws_volume_attachment.cyhy_reporter_data_attachment,
  ]

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
