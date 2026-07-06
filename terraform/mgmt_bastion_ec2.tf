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

# The extra variables passed into the Ansible provisioner below
resource "terraform_data" "mgmt_bastion_ansible_provisioner_extra_vars" {
  count = var.enable_mgmt_vpc ? length(aws_instance.mgmt_bastion) : 0

  input = "'host=${aws_instance.mgmt_bastion[count.index].public_ip} host_groups=mgmt_bastion'"
}

# Provision a Management Bastion EC2 instance via Ansible
resource "terraform_data" "mgmt_bastion_ansible_provisioner" {
  count = var.enable_mgmt_vpc ? length(aws_instance.mgmt_bastion) : 0

  # Re-run this provisioner when:
  #  * The extra variables passed to Ansible are modified
  #  * The target EC2 instance is replaced or destroyed
  #  * The main Ansible playbook is updated
  #  * Any Ansible role playbooks for this instance are updated
  triggers_replace = {
    ansible_extra_vars     = terraform_data.mgmt_bastion_ansible_provisioner_extra_vars[count.index].input
    instance_id            = aws_instance.mgmt_bastion[count.index].id
    playbook_groups_sha1   = filesha1("${path.module}/../ansible/roles/groups/tasks/main.yml")
    playbook_main_sha1     = filesha1("${path.module}/../ansible/playbook.yml")
    playbook_mgmt_ops_sha1 = filesha1("${path.module}/../ansible/roles/mgmt_ops/tasks/main.yml")
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.mgmt_bastion[count.index].public_ip},' ../ansible/playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no' --user=${var.remote_ssh_user} --extra-vars ${terraform_data.mgmt_bastion_ansible_provisioner_extra_vars[count.index].input}"
  }
}
