# Allow SSH egress to the scanner security group
resource "aws_security_group_rule" "private_ssh_egress_to_scanner" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow HTTPS egress anywhere
resource "aws_security_group_rule" "private_https_egress_to_anywhere" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 443
  to_port = 443
}

# Allow SSH ingress from the bastion
resource "aws_security_group_rule" "private_ssh_ingress_from_bastion" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_bastion.private_ip}/32"
  ]
  from_port = 22
  to_port = 22
}

# Allow MongoDB ingress from the BOD private security group
resource "aws_security_group_rule" "private_mongodb_ingress_from_bod_private" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.bod_docker_sg.id}"
  from_port = 27017
  to_port = 27017
}

# Allow MongoDB ingress from the bastion security group
resource "aws_security_group_rule" "private_mongodb_ingress_from_bastion" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_bastion_sg.id}"
  from_port = 27017
  to_port = 27017
}

# Allow MongoDB ingress from the reporter
resource "aws_security_group_rule" "private_mongodb_ingress_from_reporter" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_reporter.private_ip}/32"
  ]
  from_port = 27017
  to_port = 27017
}

# Allow MongoDB egress to Mongo host
resource "aws_security_group_rule" "private_mongodb_egress_to_mongo_host" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_mongo.private_ip}/32"
  ]
  from_port = 27017
  to_port = 27017
}
