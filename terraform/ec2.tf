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

resource "aws_instance" "mongo" {
  ami = "${data.aws_ami.mongo.id}"
  instance_type = "t2.micro"
  # ebs_optimized = true
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

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

resource "aws_ebs_volume" "mongo_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = 20
  iops = 1000
  
  tags = "${var.tags}"
}

resource "aws_ebs_volume" "mongo_journal" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = 8
  iops = 250
  
  tags = "${var.tags}"
}

resource "aws_ebs_volume" "mongo_log" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = 8
  iops = 100
  
  tags = "${var.tags}"
}

resource "aws_volume_attachment" "mongo_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id = "${aws_ebs_volume.mongo_data.id}"
  instance_id = "${aws_instance.mongo.id}"
}

resource "aws_volume_attachment" "mongo_journal_attachment" {
  device_name = "/dev/xvdc"
  volume_id = "${aws_ebs_volume.mongo_journal.id}"
  instance_id = "${aws_instance.mongo.id}"
}

resource "aws_volume_attachment" "mongo_log_attachment" {
  device_name = "/dev/xvdd"
  volume_id = "${aws_ebs_volume.mongo_log.id}"
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
