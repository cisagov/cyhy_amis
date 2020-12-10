data "aws_ami" "nessus" {
  filter {
    name = "name"
    values = [
      "cyhy-nessus-hvm-*-x86_64-ebs",
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
  count             = local.nessus_instance_count # Set by configure.py
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = aws_subnet.nessus_scanner_subnet.id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = local.production_workspace ? 100 : 16
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.nessus_scanner_sg.id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_cloud_init_tasks.rendered

  tags = merge(
    var.tags,
    {
      "Name"           = format("Manual CyHy Nessus %02d", count.index + 1)
      "Publish Egress" = "True"
    },
  )

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
  tags = merge(
    var.tags,
    {
      "Name"           = format("Manual CyHy Nessus EIP %d", count.index + 1)
      "Publish Egress" = "True"
    },
  )
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

# load in the dynamically created provisioner modules
module "dyn_nessus" {
  source                  = "./dyn_nessus"
  nessus_public_ips       = aws_eip_association.nessus_eip_assocs[*].public_ip
  nessus_activation_codes = var.nessus_activation_codes
  remote_ssh_user         = var.remote_ssh_user
}
