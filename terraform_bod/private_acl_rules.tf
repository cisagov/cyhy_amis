# Allow ssh ingress from the public subnet
resource "aws_network_acl_rule" "private_ingress_from_public_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

# Allow ingress via ephemeral ports from anywhere via TCP or UDP
resource "aws_network_acl_rule" "private_ingress_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 110
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "private_ingress_anywhere_via_ephemeral_ports_udp" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 111
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow outbound HTTP and HTTPS
resource "aws_network_acl_rule" "private_egress_anywhere_via_http" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 131
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# Allow outbound SMTP
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_25" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 25
  to_port = 25
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_465" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 141
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 465
  to_port = 465
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 142
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 587
  to_port = 587
}

# Allow egress anywhere via DNS.  This is so the NAT gateway can relay
# the corresponding requests from the private subnet.
resource "aws_network_acl_rule" "private_egress_anywhere_via_dns_tcp" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_dns_udp" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 151
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}

# Allow egress to the public subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_public_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 160
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}
