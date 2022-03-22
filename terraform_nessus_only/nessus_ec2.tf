data "aws_ami" "nessus" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefix}-nessus-hvm-*-x86_64-ebs",
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

resource "aws_instance" "nessus" {
  ami               = data.aws_ami.nessus.id
  instance_type     = "m5.large"
  count             = var.nessus_instance_count
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = aws_subnet.nessus_scanner_subnet.id

  # AWS Instance Meta-Data Service (IMDS) options
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
    volume_size = local.production_workspace ? 100 : 16
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.nessus_scanner_sg.id,
  ]

  user_data_base64     = data.template_cloudinit_config.ssh_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.nessus.name

  tags = {
    "Name"           = format("Manual CyHy Nessus %02d", count.index + 1)
    "Publish Egress" = "True"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# The Elastic IPs for *production* Nessus instances.  These are within the
# block of EIPs that AWS assigned for CyHy; see variables.tf for details.
data "aws_eip" "nessus_eips" {
  count = local.production_workspace ? length(aws_instance.nessus) : 0
  public_ip = cidrhost(
    var.cyhy_elastic_ip_cidr_block,
    var.nessus_first_elastic_ip_offset + count.index,
  )
}

# The Elastic IP for *non-production* CyHy Nessus instances. These EIPs are
# only created in *non-production* workspaces and are randomly-assigned
# public IP addresses for temporary use.
resource "aws_eip" "nessus_random_eips" {
  count = local.production_workspace ? 0 : length(aws_instance.nessus)
  vpc   = true

  tags = {
    "Name"           = format("Manual CyHy Nessus EIP %d", count.index + 1)
    "Publish Egress" = "True"
  }
}

# Associate the appropriate Elastic IPs above with the Nessus instances.
# Since our elastic IPs are handled differently in production vs.
# non-production workspaces, their corresponding terraform resources
# (data.aws_eip.nessus_eips, aws_eip.nessus_random_eips) may or may not be
# created.  To handle that, we use "splat syntax" (the *), which resolves to
# either an empty list (if the resource is not present in the current
# workspace) or a valid list (if the resource is present).  Then we
# use coalescelist() to choose the (non-empty) list containing the
# valid eip.id. Finally, we use element() to choose the appropriate
# element in that non-empty list, which is the allocation_id of our
# elastic IP.  See
# https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# VOTED WORST LINE OF TERRAFORM 2019 (so far) BY DEV TEAM WEEKLY!!
resource "aws_eip_association" "nessus_eip_assocs" {
  count       = length(aws_instance.nessus)
  instance_id = aws_instance.nessus[count.index].id
  allocation_id = element(
    coalescelist(
      data.aws_eip.nessus_eips[*].id,
      aws_eip.nessus_random_eips[*].id,
    ),
    count.index,
  )
}

# Provision a Nessus EC2 instance via Ansible
module "nessus_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = length(aws_instance.nessus)


  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no'"
  ]

  envs = [
    # If you terminate all the existing Nessus instances and then run apply,
    # the list aws_eip_association.nessus_eip_assocs[*].public_ip is empty at
    # that time.  Then there is an error condition when Terraform evaluates
    # what must be done for the apply because you are trying to use element()
    # to reference indices in an empty list.  The list will be populated with
    # the actual values as the apply runs, so we just need to get past the
    # pre-apply stage.  Therefore this ugly hack works.
    #
    # If you find a better way, please use it and get rid of this
    # affront to basic decency.
    "host=${length(aws_eip_association.nessus_eip_assocs[*].public_ip) > 0 ? element(aws_eip_association.nessus_eip_assocs[*].public_ip, count.index) : ""}",
    "host_groups=nessus",
    "nessus_activation_code=${var.nessus_activation_codes[count.index]}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}
