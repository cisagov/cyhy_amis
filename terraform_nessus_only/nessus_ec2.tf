data "aws_ami" "nessus" {
  filter {
    name = "name"
    values = [
      "cyhy-nessus-hvm-*-x86_64-ebs"
    ]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"] # This is us
  most_recent = true
}

resource "aws_instance" "nessus" {
  # Number of Nessus instances to create
  count = "${terraform.workspace == "production" ? 3 : 1}"

  ami = "${data.aws_ami.nessus.id}"
  instance_type = "m4.large"
  ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  subnet_id = "${aws_subnet.nessus_scanner_subnet.id}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
    delete_on_termination = false
  }

  vpc_security_group_ids = [
    "${aws_security_group.nessus_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", format("Manual CyHy Nessus %02d", count.index+1)))}"

  lifecycle {
    prevent_destroy = true
  }
}
