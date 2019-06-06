data "aws_ami" "cyhy_mongo" {
  filter {
    name = "name"
    values = [
      "cyhy-mongo-hvm-*-x86_64-ebs",
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

# IAM assume role policy document for the Mongo IAM role to be used by
# the Mongo EC2 instance
data "aws_iam_policy_document" "cyhy_mongo_assume_role_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The Mongo IAM role to be used by the Mongo EC2 instance
resource "aws_iam_role" "cyhy_mongo_role" {
  assume_role_policy = data.aws_iam_policy_document.cyhy_mongo_assume_role_doc.json
}

# The cyhy-archive S3 policy for our role
resource "aws_iam_role_policy" "archive_cyhy_mongo_policy" {
  role   = aws_iam_role.cyhy_mongo_role.id
  policy = data.aws_iam_policy_document.s3_cyhy_archive_write_doc.json
}

# IAM policy document that only allows GETting from the dmarc-import
# Elasticsearch database.  This will be applied to the role we are
# creating.
data "aws_iam_policy_document" "es_cyhy_mongo_doc" {
  statement {
    effect = "Allow"

    actions = [
      "es:ESHttpGet",
    ]

    resources = [
      var.dmarc_import_es_arn,
      "${var.dmarc_import_es_arn}/*",
    ]
  }
}

# The Elasticsearch policy for our role
resource "aws_iam_role_policy" "es_cyhy_mongo_policy" {
  role   = aws_iam_role.cyhy_mongo_role.id
  policy = data.aws_iam_policy_document.es_cyhy_mongo_doc.json
}

# IAM policy document that that allows write permissions on the MOE
# bucket.  This will be applied to the role we are creating.
data "aws_iam_policy_document" "s3_cyhy_mongo_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.moe_bucket.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.moe_bucket.arn}/*",
    ]
  }
}

# The S3 policy for our role
resource "aws_iam_role_policy" "s3_cyhy_mongo_policy" {
  role   = aws_iam_role.cyhy_mongo_role.id
  policy = data.aws_iam_policy_document.s3_cyhy_mongo_doc.json
}

# The instance profile to be used by the CyHy Mongo EC2 instance.
resource "aws_iam_instance_profile" "cyhy_mongo" {
  role = aws_iam_role.cyhy_mongo_role.name
}

resource "aws_instance" "cyhy_mongo" {
  count                       = local.mongo_instance_count
  ami                         = data.aws_ami.cyhy_mongo.id
  instance_type               = local.production_workspace ? "m5.12xlarge" : "t3.micro"
  availability_zone           = "${var.aws_region}${var.aws_availability_zone}"
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_and_mongo_cloud_init_tasks.rendered

  # Give this instance the access needed for archiving and doing daily
  # extracts
  iam_instance_profile = aws_iam_instance_profile.cyhy_mongo.name

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Mongo, Commander"
    },
  )
  # We add some explicit tags to the Mongo volumes below, so we don't
  # want to use volume_tags here
  # volume_tags = "${merge(var.tags, map("Name", "CyHy Mongo"))}"
}

# Provision the mongo EC2 instance via Ansible
# TODO when we start using multiple mongo, move this to a dyn_mongo module
# TODO see pattern of nmap and nessus
module "cyhy_mongo_ansible_provisioner" {
  source = "github.com/jsf9k/terraform-null-ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'",
  ]
  envs = [
    "ANSIBLE_SSH_RETRIES=5",
    "host=${aws_instance.cyhy_mongo[0].private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "cyhy_archive_s3_bucket_name=${aws_s3_bucket.cyhy_archive.bucket}",
    "cyhy_archive_s3_bucket_region=${var.aws_region}",
    "host_groups=mongo,cyhy_commander,cyhy_archive",
    "production_workspace=${local.production_workspace}",
    "aws_region=${var.aws_region}",
    "dmarc_import_aws_region=${var.dmarc_import_aws_region}",
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
  type              = "io1"
  size              = local.production_workspace ? 200 : 20
  iops              = 1000
  encrypted         = true

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Mongo Data"
    },
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "cyhy_mongo_journal" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io1"
  size              = 8
  iops              = 250
  encrypted         = true

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Mongo Journal"
    },
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ebs_volume" "cyhy_mongo_log" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type              = "io1"
  size              = 8
  iops              = 100
  encrypted         = true

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Mongo Log"
    },
  )

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "cyhy_mongo_data_attachment" {
  device_name = var.mongo_disks["data"]
  volume_id   = aws_ebs_volume.cyhy_mongo_data.id
  instance_id = aws_instance.cyhy_mongo[0].id

  # Terraform attempts to destroy the volume attachments before it attempts to
  # destroy the EC2 instance they are attached to.  EC2 does not like that and
  # it results in the failed destruction of the volume attachments.  To get
  # around this, we explicitly terminate the cyhy_mongo volume via the AWS CLI
  # in a destroy provisioner; this gracefully shuts down the instance and
  # allows terraform to successfully destroy the volume attachments.
  # Terraform attempts to destroy the volume attachments before it attempts to
  # destroy the EC2 instance they are attached to.  EC2 does not like that and
  # it results in the failed destruction of the volume attachments.  To get
  # around this, we explicitly terminate the cyhy_mongo volume via the AWS CLI
  # in a destroy provisioner; this gracefully shuts down the instance and
  # allows terraform to successfully destroy the volume attachments.
  provisioner "local-exec" {
    when       = destroy
    command    = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.cyhy_mongo[0].id}"
    on_failure = continue
  }

  # Wait until cyhy_mongo instance is terminated before continuing on
  # Wait until cyhy_mongo instance is terminated before continuing on
  provisioner "local-exec" {
    when    = destroy
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.cyhy_mongo[0].id}"
  }

  skip_destroy = true
}

resource "aws_volume_attachment" "cyhy_mongo_journal_attachment" {
  device_name = var.mongo_disks["journal"]
  volume_id   = aws_ebs_volume.cyhy_mongo_journal.id
  instance_id = aws_instance.cyhy_mongo[0].id

  provisioner "local-exec" {
    when       = destroy
    command    = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.cyhy_mongo[0].id}"
    on_failure = continue
  }

  # Wait until cyhy_mongo instance is terminated before continuing on
  # Wait until cyhy_mongo instance is terminated before continuing on
  provisioner "local-exec" {
    when    = destroy
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.cyhy_mongo[0].id}"
  }

  skip_destroy = true
}

resource "aws_volume_attachment" "cyhy_mongo_log_attachment" {
  device_name = var.mongo_disks["log"]
  volume_id   = aws_ebs_volume.cyhy_mongo_log.id
  instance_id = aws_instance.cyhy_mongo[0].id

  provisioner "local-exec" {
    when       = destroy
    command    = "aws --region=${var.aws_region} ec2 terminate-instances --instance-ids ${aws_instance.cyhy_mongo[0].id}"
    on_failure = continue
  }

  # Wait until cyhy_mongo instance is terminated before continuing on
  # Wait until cyhy_mongo instance is terminated before continuing on
  provisioner "local-exec" {
    when    = destroy
    command = "aws --region=${var.aws_region} ec2 wait instance-terminated --instance-ids ${aws_instance.cyhy_mongo[0].id}"
  }

  skip_destroy = true
}

