data "aws_ami" "nessus" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefixes.nessus}-nessus-hvm-*-x86_64-ebs",
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

resource "aws_instance" "cyhy_nessus" {
  ami               = data.aws_ami.nessus.id
  instance_type     = local.production_workspace ? "m5.2xlarge" : "m5.large"
  count             = var.nessus_instance_count
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = aws_subnet.cyhy_vulnscanner_subnet.id

  root_block_device {
    volume_size = local.production_workspace ? 200 : 16
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_scanner_sg.id,
  ]

  depends_on = [
    # This volume is needed for cyhy-runner jobs
    aws_ebs_volume.nessus_cyhy_runner_data,
  ]

  user_data_base64     = data.cloudinit_config.cyhy_nessus_cloud_init_tasks[count.index].rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_nessus.name

  tags = {
    "Name"           = format("CyHy Nessus - vulnscan%d", count.index + 1)
    "Publish Egress" = "True"
  }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = format("CyHy Nessus - vulnscan%d", count.index + 1)
    },
  )

  # If the instance is destroyed we will have to reset the license to nessus
  lifecycle {
    prevent_destroy = true
  }
}

# The Elastic IPs for the *production* CyHy Nessus instances.  These
# EIPs can be created via dhs-ncats/elastic-ips-terraform or manually,
# and are intended to be a public IP address that rarely changes.
data "aws_eip" "cyhy_nessus_eips" {
  count = local.production_workspace ? var.nessus_instance_count : 0
  public_ip = cidrhost(
    var.cyhy_elastic_ip_cidr_block,
    var.cyhy_vulnscan_first_elastic_ip_offset + count.index,
  )
}

# The Elastic IP for the *non-production* CyHy Nessus instances.
# These EIPs are only created in *non-production* workspaces and are
# randomly-assigned public IP address for temporary use.
resource "aws_eip" "cyhy_nessus_random_eips" {
  count = local.production_workspace ? 0 : var.nessus_instance_count
  vpc   = true
  tags = {
    "Name"           = format("CyHy Nessus EIP %d", count.index + 1)
    "Publish Egress" = "True"
  }
}

# Associate the appropriate Elastic IPs above with the CyHy Nessus
# instances.
resource "aws_eip_association" "cyhy_nessus_eip_assocs" {
  count         = var.nessus_instance_count
  instance_id   = aws_instance.cyhy_nessus[count.index].id
  allocation_id = local.nessus_public_ips[count.index].id
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
  count             = var.nessus_instance_count
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  type      = "gp3"
  size      = local.production_workspace ? 2 : 1
  encrypted = true

  tags = { "Name" = format("CyHy Nessus - vulnscan%d", count.index + 1) }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "nessus_cyhy_runner_data_attachment" {
  count       = var.nessus_instance_count
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.nessus_cyhy_runner_data[count.index].id
  instance_id = aws_instance.cyhy_nessus[count.index].id

  stop_instance_before_detaching = true
}

# Provision a Nessus EC2 instance via Ansible
module "cyhy_nessus_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = length(aws_instance.cyhy_nessus)

  # Ensure any EBS volumes are attached before running Ansible
  depends_on = [
    aws_volume_attachment.nessus_cyhy_runner_data_attachment,
  ]

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    # If you terminate all the existing Nessus instances and then run apply,
    # the list aws_instance.cyhy_nessus[*].private_ip is empty at that time.
    # Then there is an error condition when Terraform evaluates what must be
    # done for the apply because you are trying to use element() to reference
    # indices in an empty list.  The list will be populated with the actual
    # values as the apply runs, so we just need to get past the pre-apply
    # stage.  Therefore this ugly hack works.
    #
    # If you find a better way, please use it and get rid of this
    # affront to basic decency.
    "host=${length(aws_instance.cyhy_nessus[*].private_ip) > 0 ? element(aws_instance.cyhy_nessus[*].private_ip, count.index) : ""}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nessus",
    "nessus_activation_code=${var.nessus_activation_codes[count.index]}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}
