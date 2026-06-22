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
  instance_type     = local.production_workspace ? "c5.12xlarge" : "m5.large"
  count             = var.nessus_instance_count
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = aws_subnet.cyhy_vulnscanner_subnet.id

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
    volume_size = local.production_workspace ? 200 : 32
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

  domain = "vpc"

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

# The extra variables passed into the Ansible provisioner below
resource "terraform_data" "cyhy_nessus_ansible_provisioner_extra_vars" {
  count = length(aws_instance.cyhy_nessus)

  input = "'bastion_host=${aws_instance.cyhy_bastion.public_ip} host=${aws_instance.cyhy_nessus[count.index].private_ip} host_groups=cyhy_runner,nessus nessus_activation_code=${var.nessus_activation_codes[count.index]} nessus_smtp_hostname=${aws_route53_record.cyhy_nessus_pub_A[count.index].name}'"
}

# Provision a Nessus EC2 instance via Ansible
resource "terraform_data" "cyhy_nessus_ansible_provisioner" {
  count = length(aws_instance.cyhy_nessus)

  # Ensure any EBS volumes are attached before running Ansible
  depends_on = [
    aws_volume_attachment.nessus_cyhy_runner_data_attachment,
  ]

  # Re-run this provisioner when:
  #  * The extra variables passed to Ansible are modified
  #  * The target EC2 instance is replaced or destroyed
  #  * The main Ansible playbook is updated
  #  * Any Ansible role playbooks for this instance are updated
  triggers_replace = {
    ansible_extra_vars   = terraform_data.cyhy_nessus_ansible_provisioner_extra_vars[count.index].input
    instance_id          = aws_instance.cyhy_nessus[count.index].id
    playbook_groups_sha1 = filesha1("${path.module}/../ansible/roles/groups/tasks/main.yml")
    playbook_main_sha1   = filesha1("${path.module}/../ansible/playbook.yml")
    playbook_nessus_sha1 = filesha1("${path.module}/../ansible/roles/nessus/tasks/main.yml")
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.cyhy_nessus[count.index].private_ip},' ../ansible/playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"' --user=${var.remote_ssh_user} --extra-vars ${terraform_data.cyhy_nessus_ansible_provisioner_extra_vars[count.index].input}"
  }
}
