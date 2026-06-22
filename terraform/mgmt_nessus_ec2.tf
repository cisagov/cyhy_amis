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

resource "terraform_data" "mgmt_nessus_ansible_provisioner_extra_vars" {
  count = var.enable_mgmt_vpc ? length(aws_instance.mgmt_nessus) : 0

  input = "'bastion_host=${try(aws_instance.mgmt_bastion[0].public_ip, "")} host=${aws_instance.mgmt_nessus[count.index].private_ip} host_groups=nessus nessus_activation_code=${var.mgmt_nessus_activation_codes[count.index]}'"
}

# Provision a Management Nessus EC2 instance via Ansible
resource "terraform_data" "mgmt_nessus_ansible_provisioner" {
  count = var.enable_mgmt_vpc ? length(aws_instance.mgmt_nessus) : 0

  # Re-run this provisioner when:
  #  * The target EC2 instance is replaced or destroyed
  #  * The main Ansible playbook is updated
  #  * Any Ansible role playbooks for this instance are updated
  triggers_replace = {
    ansible_extra_vars   = terraform_data.mgmt_nessus_ansible_provisioner_extra_vars[count.index].input
    instance_id          = aws_instance.mgmt_nessus[count.index].id
    playbook_groups_sha1 = filesha1("${path.module}/../ansible/roles/groups/tasks/main.yml")
    playbook_main_sha1   = filesha1("${path.module}/../ansible/playbook.yml")
    playbook_nessus_sha1 = filesha1("${path.module}/../ansible/roles/nessus/tasks/main.yml")
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.mgmt_nessus[count.index].private_ip},' ../ansible/playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${try(aws_instance.mgmt_bastion[0].public_ip, "")}\"' --user=${var.remote_ssh_user} --extra-vars ${terraform_data.mgmt_nessus_ansible_provisioner_extra_vars[count.index].input}"
  }
}
