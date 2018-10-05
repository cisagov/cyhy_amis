# Allow egress to the both scanner subnets via ssh
resource "aws_network_acl_rule" "private_egress_to_portscanner_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_portscanner_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

resource "aws_network_acl_rule" "private_egress_to_vulnscanner_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 101
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_vulnscanner_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress to the mongo host via the MongoDB port
resource "aws_network_acl_rule" "private_egress_to_mongo_via_mongo" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 102
  rule_action = "allow"
  cidr_block = "${aws_instance.cyhy_mongo.private_ip}/32"
  from_port = 27017
  to_port = 27017
}

# Allow egress anywhere via https
# Needed to pull files from GitHub and external data sources (e.g. usgs.gov)
resource "aws_network_acl_rule" "cyhy_private_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 103
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# Allow ingress from anywhere via ephemeral ports
# Note: includes ingress from the BOD 18-01 private subnet via mongodb
resource "aws_network_acl_rule" "private_ingress_from_anywhere_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 104
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
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

# Allow egress to the BOD 18-01 private subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_bod_private_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}
