# The bastion EC2 instance
resource "aws_instance" "mgmt_bastion" {
  count = var.enable_mgmt_vpc ? 1 : 0

  ami               = data.aws_ami.bastion.id
  instance_type     = "t3.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id                   = aws_subnet.mgmt_public_subnet[0].id
  associate_public_ip_address = true

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
    volume_size = 20
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.mgmt_bastion_sg[0].id,
  ]

  user_data_base64 = data.cloudinit_config.mgmt_bastion_cloud_init_tasks[0].rendered

  tags = { "Name" = "Management Bastion" }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = "Management Bastion"
    },
  )
}

# Provision a Management Bastion EC2 instance via Ansible
module "mgmt_bastion_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"
  count  = var.enable_mgmt_vpc ? length(aws_instance.mgmt_bastion) : 0

  arguments = [
    "--ssh-common-args='-o StrictHostKeyChecking=no'",
    "--user=${var.remote_ssh_user}",
  ]
  dry_run = false
  envs = [
    "host=${aws_instance.mgmt_bastion[*].public_ip[count.index]}",
    "host_groups=mgmt_bastion",
  ]
  playbook = "../ansible/playbook.yml"
}
