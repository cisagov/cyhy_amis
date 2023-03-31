resource "aws_instance" "mgmt_nessus" {
  count = var.enable_mgmt_vpc ? var.mgmt_nessus_instance_count : 0

  ami               = data.aws_ami.nessus.id
  instance_type     = "m5.large"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = aws_subnet.mgmt_private_subnet[0].id

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
    volume_size = local.production_workspace ? 100 : 16
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.mgmt_scanner_sg[0].id,
  ]

  user_data_base64 = data.cloudinit_config.mgmt_nessus_cloud_init_tasks[count.index].rendered

  tags = { "Name" = format("Management Nessus - vulnscan%d", count.index + 1) }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = format("Management Nessus - vulnscan%d", count.index + 1)
    },
  )

  # If the instance is destroyed we will have to reset the license to nessus
  lifecycle {
    prevent_destroy = true
  }
}

# Provision a Management Nessus EC2 instance via Ansible
module "mgmt_nessus_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = var.enable_mgmt_vpc ? length(aws_instance.mgmt_nessus) : 0

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.mgmt_bastion[*].public_ip[count.index]}\"'"
  ]
  envs = [
    # If you terminate all the existing management Nessus instances
    # and then run apply, the list aws_instance.mgmt_nessus[*].private_ip
    # is empty at that time.  Then there is an error condition when Terraform
    # evaluates what must be done for the apply because you are trying to use
    # element() to reference indices in an empty list.  The list will be
    # populated with the actual values as the apply runs, so we just need to
    # get past the pre-apply stage.  Therefore this ugly hack works.
    #
    # If you find a better way, please use it and get rid of this
    # affront to basic decency.
    "host=${length(aws_instance.mgmt_nessus[*].private_ip) > 0 ? element(aws_instance.mgmt_nessus[*].private_ip, count.index) : ""}",
    "bastion_host=${aws_instance.mgmt_bastion[*].public_ip[count.index]}",
    "host_groups=nessus",
    "nessus_activation_code=${var.mgmt_nessus_activation_codes[count.index]}"
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}
