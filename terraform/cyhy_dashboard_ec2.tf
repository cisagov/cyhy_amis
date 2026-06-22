# The docker AMI
data "aws_ami" "dashboard" {
  filter {
    name = "name"
    values = [
      "${var.ami_prefixes.dashboard}-dashboard-hvm-*-x86_64-ebs",
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

# The cyhy dashboard EC2 instance
resource "aws_instance" "cyhy_dashboard" {
  ami           = data.aws_ami.dashboard.id
  instance_type = local.production_workspace ? "m5zn.xlarge" : "t3.medium"

  # This is the private subnet
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

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
    volume_size = local.production_workspace ? 100 : 10
    volume_type = "gp3"
  }

  vpc_security_group_ids = [
    aws_security_group.cyhy_private_sg.id,
  ]

  # The dashboard needs the database available to function
  depends_on = [
    aws_instance.cyhy_mongo,
  ]

  user_data_base64     = data.cloudinit_config.cyhy_dashboard_cloud_init_tasks.rendered
  iam_instance_profile = aws_iam_instance_profile.cyhy_dashboard.name

  tags = { "Name" = "CyHy Dashboard" }

  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(
    data.aws_default_tags.default.tags,
    {
      "Name" = "CyHy Dashboard"
    },
  )
}

# The extra variables passed into the Ansible provisioner below
resource "terraform_data" "cyhy_dashboard_ansible_provisioner_extra_vars" {
  input = "'bastion_host=${aws_instance.cyhy_bastion.public_ip} host=${aws_instance.cyhy_dashboard.private_ip} host_groups=cyhy_dashboard'"
}

# Provision the cyhy_dashboard EC2 instance via Ansible
resource "terraform_data" "cyhy_dashboard_ansible_provisioner" {
  # Ensure the EC2 instance is created before running Ansible
  depends_on = [
    aws_instance.cyhy_dashboard,
  ]

  # Re-run this provisioner when:
  #  * The extra variables passed to Ansible are modified
  #  * The target EC2 instance is replaced or destroyed
  #  * The main Ansible playbook is updated
  #  * Any Ansible role playbooks for this instance are updated
  triggers_replace = {
    ansible_extra_vars      = terraform_data.cyhy_dashboard_ansible_provisioner_extra_vars.input
    instance_id             = aws_instance.cyhy_dashboard.id
    playbook_dashboard_sha1 = filesha1("${path.module}/../ansible/roles/cyhy_dashboard/tasks/main.yml")
    playbook_groups_sha1    = filesha1("${path.module}/../ansible/roles/groups/tasks/main.yml")
    playbook_main_sha1      = filesha1("${path.module}/../ansible/playbook.yml")
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.cyhy_dashboard.private_ip},' ../ansible/playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"' --user=${var.remote_ssh_user} --extra-vars ${terraform_data.cyhy_dashboard_ansible_provisioner_extra_vars.input}"
  }
}
