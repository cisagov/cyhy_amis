# Allow ssh ingress from the public subnet
resource "aws_network_acl_rule" "private_ingress_from_public_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow ingress via ephemeral ports from anywhere via TCP
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

# Allow ingress via ephemeral ports from Google DNS via UDP
resource "aws_network_acl_rule" "private_ingress_from_google_dns_via_ephemeral_ports_udp_1" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 111
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "private_ingress_from_google_dns_via_ephemeral_ports_udp_2" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 112
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 1024
  to_port = 65535
}

# Allow outbound HTTP
resource "aws_network_acl_rule" "private_egress_anywhere_via_http" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 119
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

# Allow outbound HTTPS
resource "aws_network_acl_rule" "private_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# Allow outbound SMTP
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 587
  to_port = 587
}

# Allow egress to Google DNS
resource "aws_network_acl_rule" "private_egress_to_google_dns_tcp_1" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 135
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "private_egress_to_google_dns_tcp_2" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 136
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "private_egress_to_google_dns_udp_1" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 137
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "private_egress_to_google_dns_udp_2" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 138
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 53
  to_port = 53
}

# Allow egress to the public subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_public_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}

# Allow MongoDB egress to the CyHy private subnet
resource "aws_network_acl_rule" "private_egress_to_cyhy_private_via_mongodb" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_private_subnet.cidr_block}"
  from_port = 27017
  to_port = 27017
}
