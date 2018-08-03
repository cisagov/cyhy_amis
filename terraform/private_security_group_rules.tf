# Allow ingress via ephemeral ports from anywhere
resource "aws_security_group_rule" "private_ingress_from_anywhere_via_ephemeral_ports" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}

# Allow SSH ingress from the scanner security group
resource "aws_security_group_rule" "private_ssh_ingress_from_scanner" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow SSH egress to the scanner security group
resource "aws_security_group_rule" "private_ssh_egress_to_scanner" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow MongoDB ingress from the BOD private security group
resource "aws_security_group_rule" "private_mongodb_ingress_from_bod_private" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${data.aws_security_group.bod_docker_sg.id}"
  from_port = 27017
  to_port = 27017
}
