# The bastion EC2 instance
resource "aws_instance" "bod_bastion" {
  ami               = data.aws_ami.bastion.id
  instance_type     = "t3.micro"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id                   = aws_subnet.bod_public_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    aws_security_group.bod_bastion_sg.id,
  ]

  user_data_base64 = data.template_cloudinit_config.ssh_cloud_init_tasks.rendered

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Bastion"
    },
  )
  volume_tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Bastion"
    },
  )
}
