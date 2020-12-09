# The bastion EC2 instance
resource "aws_instance" "mgmt_bastion" {
  count = var.enable_mgmt_vpc ? 1 : 0

  ami               = data.aws_ami.bastion.id
  instance_type     = "t3.micro"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id                   = aws_subnet.mgmt_public_subnet[0].id
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.mgmt_bastion_sg[0].id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_cloud_init_tasks.rendered

  tags = merge(
    var.tags,
    {
      "Name" = "Management Bastion"
    },
  )
  volume_tags = merge(
    var.tags,
    {
      "Name" = "Management Bastion"
    },
  )
}

# load in the dynamically created provisioner modules
module "dyn_mgmt_bastion" {
  source                 = "./dyn_mgmt_bastion"
  mgmt_bastion_public_ip = aws_instance.mgmt_bastion[*].public_ip
  remote_ssh_user        = var.remote_ssh_user
}
