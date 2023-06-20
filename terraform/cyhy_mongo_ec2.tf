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

  # AWS Instance Metadata Service (IMDS) options
  metadata_options {
    # Enable IMDS (this is the default value)
    http_endpoint = "enabled"
    # Restrict put responses from IMDS to a single hop (this is the
    # default value).  This effectively disallows the retrieval of an
    # IMDSv2 token via this machine from anywhere else.
    http_put_response_hop_limit = 1
    # Require IMDS tokens AKA require the use of IMDSv2
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  depends_on = [
    # The CloudWatch Agent running on these instances will create
    # these log groups when they start up, but the CloudWatch log
    # metric filters we create for detecting NVD and KEV sync failures
    # require that they exist; therefore we create the log groups via
    # Terraform.  At the same time, we want to avoid a race condition
    # where these instances start up and create the log groups before
    # the Terraform code can; hence, we add the log group resources to
    # the depends_on clause for the instances.
    #
    # Instead of coming up with a clever way to isolate the particular
    # log group that each instance depends on, I just list the whole
    # set here.  The effect is the same.
    aws_cloudwatch_log_group.instance_logs,
    # These volumes are needed for MongoDB to function
    aws_ebs_volume.cyhy_mongo_data,
    aws_ebs_volume.cyhy_mongo_journal,
    aws_ebs_volume.cyhy_mongo_log,
    # The cyhy-commander needs these instances available to pull/push work
    aws_instance.cyhy_nessus,
    aws_instance.cyhy_nmap,
  ]

  user_data_base64     = data.cloudinit_config.cyhy_mongo_cloud_init_tasks[count.index].rendered
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

  stop_instance_before_detaching = true
}

resource "aws_volume_attachment" "cyhy_mongo_journal_attachment" {
  device_name = var.mongo_disks["journal"]
  volume_id   = aws_ebs_volume.cyhy_mongo_journal.id
  instance_id = aws_instance.cyhy_mongo[0].id

  stop_instance_before_detaching = true
}

resource "aws_volume_attachment" "cyhy_mongo_log_attachment" {
  device_name = var.mongo_disks["log"]
  volume_id   = aws_ebs_volume.cyhy_mongo_log.id
  instance_id = aws_instance.cyhy_mongo[0].id

  stop_instance_before_detaching = true
}

# Provision the mongo EC2 instance via Ansible
module "cyhy_mongo_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = length(aws_instance.cyhy_mongo)

  # Ensure any EBS volumes are attached before running Ansible
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
    # cyhy-commander configuration values
    "jobs_per_nessus_host=${var.commander_config.jobs_per_nessus_host}",
    "jobs_per_nmap_host=${var.commander_config.jobs_per_nmap_host}",
    "nessus_hosts=${join(",", formatlist("vulnscan%d", range(1, var.nessus_instance_count + 1)))}",
    "next_scan_limit=${var.commander_config.next_scan_limit}",
    "nmap_hosts=${join(",", formatlist("portscan%d", range(1, var.nmap_instance_count + 1)))}",
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}
