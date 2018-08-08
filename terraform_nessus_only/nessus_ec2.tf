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

# Security group for the Nessus scanner
resource "aws_security_group" "nessus_scanner_sg" {
  # Use the default VPC
  
  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners"))}"
}

resource "aws_instance" "nessus" {
  ami = "${data.aws_ami.nessus.id}"
  instance_type = "m4.large"
  ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # Use a subnet in the default VPC
  subnet_id = "${var.default_aws_subnet_id}"
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.nessus_scanner_sg.id}"
  ]

  user_data = "${data.template_cloudinit_config.ssh_cloud_init_tasks.rendered}"

  tags = "${merge(var.tags, map("Name", "Manual CyHy Nessus"))}"
}
