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
  instance_type = local.production_workspace ? "c5.xlarge" : "t3.medium"

  # This is the private subnet
  subnet_id                   = aws_subnet.cyhy_private_subnet.id
  associate_public_ip_address = false

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

  user_data_base64     = data.template_cloudinit_config.cyhy_ssh_cloud_init_tasks.rendered
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

# Provision the Docker EC2 instance via Ansible
module "cyhy_dashboard_ansible_provisioner" {
  source = "github.com/cloudposse/terraform-null-ansible"

  arguments = [
    "--user=${var.remote_ssh_user}",
    "--ssh-common-args='-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -W %h:%p -o StrictHostKeyChecking=no -q ${var.remote_ssh_user}@${aws_instance.cyhy_bastion.public_ip}\"'",
  ]
  envs = [
    "host=${aws_instance.cyhy_dashboard.private_ip}",
    "bastion_host=${aws_instance.cyhy_bastion.public_ip}",
    "host_groups=cyhy_dashboard",
  ]
  playbook = "../ansible/playbook.yml"
  dry_run  = false
}
