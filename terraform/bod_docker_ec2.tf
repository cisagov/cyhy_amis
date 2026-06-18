# The docker AMI
data "aws_ami" "bod_docker" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefixes.docker}-docker-hvm-*-x86_64-ebs",
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

# The docker EC2 instance
resource "aws_instance" "bod_docker" {
  ami               = data.aws_ami.bod_docker.id
  instance_type     = local.production_workspace ? "r5.xlarge" : "t3.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the private subnet
  subnet_id = aws_subnet.bod_docker_subnet.id

  # AWS Instance Metadata Service (IMDS) options
  metadata_options {
    # Enable IMDS (this is the default value)
    http_endpoint = "enabled"
    # Normally we restrict put responses from IMDS to a single hop
    # (this is the default value).  This effectively disallows the
    # retrieval of an IMDSv2 token via this machine from anywhere
    # else.
    #
    # In this case we set the hop limit to two, since some of the Docker
    # containers hosted on this instance need to retrieve credentials from
    # IMDS. The BOD 18-01 scanning orchestration and cisagov/cyhy-mailer
    # Docker containers need to access the dmarc-import Elasticsearch
    # database and send email using SES. The cisagov/code-gov-update
    # Docker container needs to send email using SES.
    http_put_response_hop_limit = 2
    # Require IMDS tokens AKA require the use of IMDSv2
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.bod_docker_sg.id,
  ]

  depends_on = [
    # This volume is needed for BOD 18-01 scanning output
    aws_ebs_volume.bod_report_data,
    # BOD 18-01 scanning needs the BOD Lambdas and the database available to function
    aws_instance.cyhy_mongo,
    aws_lambda_function.lambdas,
  ]

  user_data_base64     = data.cloudinit_config.bod_docker_cloud_init_tasks.rendered
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
  type              = "io2"
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

  stop_instance_before_detaching = true
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
#
# We use the minimum size for io2 volumes because the output of the VDP process
# is small.
resource "aws_ebs_volume" "vdp_report_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io2"
  size              = 4
  iops              = 100
  encrypted         = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "vdp_report_data_attachment" {
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.vdp_report_data.id
  instance_id = aws_instance.bod_docker.id

  skip_destroy = true
}

# Provision the Docker EC2 instance via Ansible
resource "null_resource" "bod_docker_ansible_provisioner" {
  # Ensure any EBS volumes are attached before running Ansible
  depends_on = [
    aws_volume_attachment.bod_report_data_attachment,
    aws_volume_attachment.vdp_report_data_attachment,
  ]

  # Re-run this provisioner when:
  #  * The target EC2 instance is replaced or destroyed
  #  * The main Ansible playbook is updated
  #  * Any Ansible role playbooks for this instance are updated
  triggers = {
    instance_id                = aws_instance.bod_docker.id
    playbook_code_gov_sha1     = filesha1("${path.module}/../ansible/roles/code_gov_update/tasks/main.yml")
    playbook_groups_sha1       = filesha1("${path.module}/../ansible/roles/groups/tasks/main.yml")
    playbook_mailer_sha1       = filesha1("${path.module}/../ansible/roles/cyhy_mailer/tasks/main.yml")
    playbook_main_sha1         = filesha1("${path.module}/../ansible/playbook.yml")
    playbook_ops_sha1          = filesha1("${path.module}/../ansible/roles/cyhy_ops/tasks/main.yml")
    playbook_orchestrator_sha1 = filesha1("${path.module}/../ansible/roles/orchestrator/tasks/main.yml")
    playbook_vdp_sha1          = filesha1("${path.module}/../ansible/roles/vdp_scanner/tasks/main.yml")
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.bod_docker.private_ip},' ../ansible/playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.bod_bastion.public_ip}\"' --user=${var.remote_ssh_user} --extra-vars 'bastion_host=${aws_instance.bod_bastion.public_ip} code_gov_update_ses_aws_region=${var.ses_aws_region} code_gov_update_ses_send_email_role=${var.ses_role_arn} cyhy_mailer_docker_compose_override_file_for_mailer=${var.docker_mailer_override_filename} cyhy_mailer_ses_aws_region=${var.ses_aws_region} cyhy_mailer_ses_send_email_role=${var.ses_role_arn} host=${aws_instance.bod_docker.private_ip} host_groups=docker,bod_docker orchestrator_aws_region=${var.aws_region} orchestrator_dmarc_import_aws_region=${var.dmarc_import_aws_region} orchestrator_dmarc_import_es_role=${var.dmarc_import_es_read_write_role_arn} production_workspace=${local.production_workspace}'"
  }
}
