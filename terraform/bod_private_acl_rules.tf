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

# Allow outbound HTTP, HTTPS, and SMTP (587) anywhere
resource "aws_network_acl_rule" "private_egress_anywhere" {
  count = "${length(local.bod_docker_egress_anywhere_ports)}"

  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = "${120 + count.index}"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
  to_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
}

# Allow egress to Google DNS
resource "aws_network_acl_rule" "private_egress_to_google_dns_1" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${135 + count.index}"
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "private_egress_to_google_dns_2" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${137 + count.index}"
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
