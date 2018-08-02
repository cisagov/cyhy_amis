# Allow ingress from the private subnet via http, https, smtp, and
# dns.  This allows EC2 instances in the private subnet to send the
# traffic they want via the NAT gateway, subject to their own security
# group and network ACL restrictions.
resource "aws_network_acl_rule" "public_ingress_from_private_via_http" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 80
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_https" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 81
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 443
  to_port = 443
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_25" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 82
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 25
  to_port = 25
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_465" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 83
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 465
  to_port = 465
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 84
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 587
  to_port = 587
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_dns_tcp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 85
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_dns_udp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 86
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 53
  to_port = 53
}

# Allow ingress from anywhere via ephemeral ports for both tcp and
# udp.  This is necessary because the return traffic to the NAT
# gateway has to enter here before it is relayed to the private
# subnet.
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 90
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ephemeral_ports_udp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 91
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow ingress from anywhere via ssh
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

# Allow egress to the private subnet via ssh
resource "aws_network_acl_rule" "public_egress_to_private_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress anywhere via http, https, smtp, and dns.  This is so
# the NAT gateway can relay the corresponding requests from the
# private subnet.
resource "aws_network_acl_rule" "public_egress_anywhere_via_http" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 141
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_25" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 25
  to_port = 25
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_465" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 151
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 465
  to_port = 465
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 152
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 587
  to_port = 587
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_dns_tcp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 160
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_dns_udp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 161
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}

# Allow egress to anywhere via TCP ephemeral ports
resource "aws_network_acl_rule" "public_egress_to_anywhere_via_tcp_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 170
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow egress to the private subnet via UDP ephemeral ports
resource "aws_network_acl_rule" "public_egress_to_private_via_udp_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 171
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}
