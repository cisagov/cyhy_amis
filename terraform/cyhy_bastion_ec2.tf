# The bastion EC2 instance
resource "aws_instance" "cyhy_bastion" {
  ami               = data.aws_ami.bastion.id
  instance_type     = local.production_workspace ? "c6gn.large" : "t4g.small"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id                   = aws_subnet.cyhy_public_subnet.id
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
    aws_security_group.cyhy_bastion_sg.id,
  ]

  user_data_base64     = data.cloudinit_config.cyhy_bastion_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_bastion.name

  tags = { "Name" = "CyHy Bastion" }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = "CyHy Bastion"
    },
  )
}

# Provision the bastion EC2 instance via Ansible
resource "null_resource" "cyhy_bastion_ansible_provisioner" {
  # Ensure the EC2 instance is created before running Ansible
  depends_on = [
    aws_instance.cyhy_bastion,
  ]

  # Re-run this provisioner when:
  #  * The target EC2 instance is replaced or destroyed
  #  * The main Ansible playbook is updated
  #  * Any Ansible role playbooks for this instance are updated
  triggers = {
    instance_id          = aws_instance.cyhy_bastion.id
    playbook_groups_sha1 = filesha1("${path.module}/../ansible/roles/groups/tasks/main.yml")
    playbook_main_sha1   = filesha1("${path.module}/../ansible/playbook.yml")
    playbook_ops_sha1    = filesha1("${path.module}/../ansible/roles/cyhy_ops/tasks/main.yml")
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.cyhy_bastion.public_ip},' ../ansible/playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no' --user=${var.remote_ssh_user} --extra-vars 'host=${aws_instance.cyhy_bastion.public_ip} host_groups=cyhy_bastion'"
  }
}
