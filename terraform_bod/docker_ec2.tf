# The bastion AMI
data "aws_ami" "docker" {
  filter {
    name = "name"
    values = [
      "cyhy-docker-hvm-*-x86_64-ebs"
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

# The docker EC2 instance
resource "aws_instance" "docker" {
  ami = "${data.aws_ami.docker.id}"
  instance_type = "t2.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  # This is the public subnet
  subnet_id = "${aws_subnet.bod_private_subnet.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  vpc_security_group_ids = [
    "${aws_security_group.bod_public_sg.id}"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Docker host"))}"
}
