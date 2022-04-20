data "aws_ami" "cyhy_mongo" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefixes.mongo}-mongo-hvm-*-x86_64-ebs",
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

resource "aws_instance" "cyhy_mongo" {
  count                       = var.mongo_instance_count
  ami                         = data.aws_ami.cyhy_mongo.id
  instance_type               = local.production_workspace ? "m5.12xlarge" : "t3.small"
  availability_zone           = "${var.aws_region}${var.aws_availability_zone}"
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  # The cyhy-commander needs these instances available to pull/push work
  depends_on = [
    aws_instance.cyhy_nessus,
    aws_instance.cyhy_nmap,
  ]

  user_data_base64     = data.template_cloudinit_config.ssh_and_mongo_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_mongo.name

  tags = { "Name" = "CyHy Mongo, Commander" }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = "CyHy Mongo Log"
    },
  )
}

# Provision the mongo EC2 instance via Ansible
module "cyhy_mongo_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = length(aws_instance.cyhy_mongo)

  depends_on = [
    aws_volume_attachment.cyhy_mongo_data_attachment,
    aws_volume_attachment.cyhy_mongo_journal_attachment,
    aws_volume_attachment.cyhy_mongo_log_attachment,
  ]

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'",
  ]
  envs = [
    "ANSIBLE_SSH_RETRIES=5",
    "host=${aws_instance.cyhy_mongo[count.index].private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "cyhy_archive_s3_bucket_name=${aws_s3_bucket.cyhy_archive.bucket}",
    "cyhy_archive_s3_bucket_region=${var.aws_region}",
    "host_groups=mongo,cyhy_commander,cyhy_archive",
    "production_workspace=${local.production_workspace}",
    "aws_region=${var.aws_region}",
    "dmarc_import_aws_region=${var.dmarc_import_aws_region}",
    "dmarc_import_es_role=${var.dmarc_import_es_role_arn}",
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
resource "aws_ebs_volume" "cyhy_mongo_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io2"
  size              = local.production_workspace ? 1024 : 20
  iops              = 1000
  encrypted         = true

  tags = { "Name" = "CyHy Mongo Data" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "cyhy_mongo_journal" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io2"
  size              = 8
  iops              = 250
  encrypted         = true

  tags = { "Name" = "CyHy Mongo Journal" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "cyhy_mongo_log" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io2"
  size              = 8
  iops              = 100
  encrypted         = true

  tags = { "Name" = "CyHy Mongo Log" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "cyhy_mongo_data_attachment" {
  device_name = var.mongo_disks["data"]
  volume_id   = aws_ebs_volume.cyhy_mongo_data.id
  instance_id = aws_instance.cyhy_mongo[0].id

  skip_destroy = true
}

resource "aws_volume_attachment" "cyhy_mongo_journal_attachment" {
  device_name = var.mongo_disks["journal"]
  volume_id   = aws_ebs_volume.cyhy_mongo_journal.id
  instance_id = aws_instance.cyhy_mongo[0].id

  skip_destroy = true
}

resource "aws_volume_attachment" "cyhy_mongo_log_attachment" {
  device_name = var.mongo_disks["log"]
  volume_id   = aws_ebs_volume.cyhy_mongo_log.id
  instance_id = aws_instance.cyhy_mongo[0].id

  skip_destroy = true
}
