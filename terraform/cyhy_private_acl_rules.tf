# Allow egress to the scanner subnet via ssh
resource "aws_network_acl_rule" "private_egress_to_scanner_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress to the mongo host via the MongoDB port
resource "aws_network_acl_rule" "private_egress_to_mongo_via_mongo" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 101
  rule_action = "allow"
  cidr_block = "${aws_instance.cyhy_mongo.private_ip}/32"
  from_port = 27017
  to_port = 27017
}

# Allow ingress from scanner subnet via ephemeral ports
resource "aws_network_acl_rule" "private_ingress_from_scanner_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 102
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}

# Allow ingress from the bastion via ssh
resource "aws_network_acl_rule" "private_ingress_from_bastion_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 110
  rule_action = "allow"
  cidr_block = "${aws_instance.cyhy_bastion.private_ip}/32"
  from_port = 22
  to_port = 22
}

# Allow egress to the bastion via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_bastion_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 111
  rule_action = "allow"
  cidr_block = "${aws_instance.cyhy_bastion.private_ip}/32"
  from_port = 1024
  to_port = 65535
}

# Allow ingress from the BOD 18-01 private subnet via mongodb
resource "aws_network_acl_rule" "private_ingress_from_bod_private_via_mongodb" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 27017
  to_port = 27017
}

# Allow egress to the BOD 18-01 private subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_bod_private_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 121
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}
