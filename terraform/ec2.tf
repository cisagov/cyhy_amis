# The Mongo AMI that we are starting
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

# The EC2 instance that is running MongoDB
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

  associate_public_ip_address = true
  subnet_id = "${aws_subnet.mongo_public_subnet.id}"
  vpc_security_group_ids = [
    "${aws_security_group.mongo_public_sg.id}"
  ]

  tags = "${var.tags}"
}

# Mongo data volume
resource "aws_ebs_volume" "mongo_data" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = 20
  iops = 1000
  
  tags = "${var.tags}"
}

# Mongo journal volume
resource "aws_ebs_volume" "mongo_journal" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = 8
  iops = 250
  
  tags = "${var.tags}"
}

# Mongo log volume
resource "aws_ebs_volume" "mongo_log" {
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"
  type = "io1"
  size = 8
  iops = 100
  
  tags = "${var.tags}"
}

# Attach the Mongo data volume to the EC2 instance
resource "aws_volume_attachment" "mongo_data_attachment" {
  device_name = "/dev/xvdb"
  volume_id = "${aws_ebs_volume.mongo_data.id}"
  instance_id = "${aws_instance.mongo.id}"
}

# Attach the Mongo journal volume to the EC2 instance
resource "aws_volume_attachment" "mongo_journal_attachment" {
  device_name = "/dev/xvdc"
  volume_id = "${aws_ebs_volume.mongo_journal.id}"
  instance_id = "${aws_instance.mongo.id}"
}

# Attach the Mongo log volume to the EC2 instance
resource "aws_volume_attachment" "mongo_log_attachment" {
  device_name = "/dev/xvdd"
  volume_id = "${aws_ebs_volume.mongo_log.id}"
  instance_id = "${aws_instance.mongo.id}"
}
