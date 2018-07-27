data "aws_ami" "mongo" {
  filter {
    name = "name"
    values = [
      "cyhy-mongo-hvm-*-x86_64-ebs"
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

resource "aws_ebs_volume" "mongo_data" {
  availability_zone = "${var.aws_region}a"
  type = "gp2"
  size = 8
  
  tags = "${var.tags}"
}

resource "aws_instance" "mongo" {
  ami = "${data.aws_ami.mongo.id}"
  instance_type = "t2.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}a"

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
    delete_on_termination = true
  }

  security_groups = [
    "${aws_security_group.mongo_sg.name}"
  ]

  tags = "${var.tags}"
}

resource "aws_volume_attachment" "mongo_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id = "${aws_ebs_volume.mongo_data.id}"
  instance_id = "${aws_instance.mongo.id}"
}

resource "aws_security_group" "mongo_sg" {
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}
