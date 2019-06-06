resource "aws_instance" "mgmt_nessus" {
  count = var.enable_mgmt_vpc * local.mgmt_nessus_instance_count

  ami               = data.aws_ami.nessus.id
  instance_type     = "m5.large"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = aws_subnet.mgmt_private_subnet[0].id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = local.production_workspace ? 100 : 16
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.mgmt_scanner_sg[0].id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_cloud_init_tasks.rendered

  tags = merge(
    var.tags,
    {
      "Name" = format("Management Nessus - vulnscan%d", count.index + 1)
    },
  )
  volume_tags = merge(
    var.tags,
    {
      "Name" = format("Management Nessus - vulnscan%d", count.index + 1)
    },
  )

  # If the instance is destroyed we will have to reset the license to nessus
  lifecycle {
    prevent_destroy = true
  }
}

# load in the dynamically created provisioner modules
module "dyn_mgmt_nessus" {
  source                       = "./dyn_mgmt_nessus"
  mgmt_bastion_public_ip       = aws_instance.mgmt_bastion[0].public_ip
  mgmt_nessus_private_ips      = aws_instance.mgmt_nessus.*.private_ip
  mgmt_nessus_activation_codes = var.mgmt_nessus_activation_codes
  remote_ssh_user              = var.remote_ssh_user
}

