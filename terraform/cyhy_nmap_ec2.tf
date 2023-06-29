data "aws_ami" "nmap" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefixes.nmap}-nmap-hvm-*-x86_64-ebs",
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

resource "aws_instance" "cyhy_nmap" {
  ami           = data.aws_ami.nmap.id
  instance_type = local.production_workspace ? "t3.medium" : "t3.small"
  count         = var.nmap_instance_count

  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # We may want to spread instances across all availability zones, however
  # this will also require creating a scanner subnet in each availability zone
  # availability_zone = "${element(data.aws_availability_zones.all.names, count.index)}"

  subnet_id = aws_subnet.cyhy_portscanner_subnet.id

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
    volume_size = local.production_workspace ? 20 : 8
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_scanner_sg.id,
  ]

  depends_on = [
    # This volume is needed for cyhy-runner jobs
    aws_ebs_volume.nmap_cyhy_runner_data,
  ]

  user_data_base64     = data.cloudinit_config.cyhy_nmap_cloud_init_tasks[count.index].rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_nmap.name

  tags = {
    "Name"           = format("CyHy Nmap - portscan%d", count.index + 1)
    "Publish Egress" = "True"
  }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = format("CyHy Nmap - portscan%d", count.index + 1)
    },
  )
}

# The Elastic IPs for the *production* CyHy nmap scanner instances.
# These EIPs can be created via dhs-ncats/elastic-ips-terraform or
# manually and are intended to be a public IP address that rarely
# changes.
data "aws_eip" "cyhy_nmap_eips" {
  count = local.production_workspace ? var.nmap_instance_count : 0
  public_ip = cidrhost(
    var.cyhy_elastic_ip_cidr_block,
    var.cyhy_portscan_first_elastic_ip_offset + count.index,
  )
}

# The Elastic IPs for the *non-production* CyHy nmap scanner
# instances.  These EIPs are only created in *non-production*
# workspaces and are randomly-assigned public IP address for temporary
# use.
resource "aws_eip" "cyhy_nmap_random_eips" {
  count = local.production_workspace ? 0 : var.nmap_instance_count
  vpc   = true
  tags = {
    "Name"           = format("CyHy Nmap EIP %d", count.index + 1)
    "Publish Egress" = "True"
  }
}

# Associate the appropriate Elastic IP above with the CyHy nmap
# instances.  Since our elastic IPs are handled differently in
# production vs. non-production workspaces, their corresponding
# terraform resources (data.aws_eip.cyhy_nmap_eips,
# data.aws_eip.cyhy_nmap_random_eips) may or may not be created.  To
# handle that, we use "splat syntax" (the *), which resolves to either
# an empty list (if the resource is not present in the current
# workspace) or a valid list (if the resource is present).  Then we
# use coalescelist() to choose the (non-empty) list containing the
# valid eip.id. Finally, we use element() to choose the first element
# in that non-empty list, which is the allocation_id of our elastic
# IP.  See
# https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# VOTED WORST LINE OF TERRAFORM 2018 (so far) BY DEV TEAM WEEKLY!!
resource "aws_eip_association" "cyhy_nmap_eip_assocs" {
  count       = var.nmap_instance_count
  instance_id = aws_instance.cyhy_nmap[count.index].id
  allocation_id = element(
    coalescelist(
      data.aws_eip.cyhy_nmap_eips[*].id,
      aws_eip.cyhy_nmap_random_eips[*].id,
    ),
    count.index,
  )
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
resource "aws_ebs_volume" "nmap_cyhy_runner_data" {
  count             = var.nmap_instance_count
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # availability_zone = "${element(data.aws_availability_zones.all.names, count.index)}"
  type      = "gp3"
  size      = local.production_workspace ? 2 : 1
  encrypted = true

  tags = { "Name" = format("CyHy Nmap - portscan%d", count.index + 1) }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_volume_attachment" "nmap_cyhy_runner_data_attachment" {
  count       = var.nmap_instance_count
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.nmap_cyhy_runner_data[count.index].id
  instance_id = aws_instance.cyhy_nmap[count.index].id

  stop_instance_before_detaching = true
}

# Provision an nmap EC2 instance via Ansible
module "cyhy_nmap_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = length(aws_instance.cyhy_nmap)

  # Ensure any EBS volumes are attached before running Ansible
  depends_on = [
    aws_volume_attachment.nmap_cyhy_runner_data_attachment,
  ]

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'"
  ]
  envs = [
    # If you terminate all the existing nmap instances and then run apply, the
    # list aws_instance.cyhy_nmap[*].private_ip is empty at that time.  Then
    # there is an error condition when Terraform evaluates what must be done
    # for the apply because you are trying to use element() to reference
    # indices in an empty list.  The list will be populated with the actual
    # values as the apply runs, so we just need to get past the pre-apply
    # stage.  Therefore this ugly hack works.
    #
    # If you find a better way, please use it and get rid of this
    # affront to basic decency.
    "host=${length(aws_instance.cyhy_nmap[*].private_ip) > 0 ? element(aws_instance.cyhy_nmap[*].private_ip, count.index) : ""}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_runner,nmap"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}
