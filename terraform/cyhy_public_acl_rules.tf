# Allow ingress from anywhere via the Nessus UI and ssh ports
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_nessus_and_ssh" {
  count = "${length(local.cyhy_trusted_ingress_ports)}"

  network_acl_id = "${aws_network_acl.cyhy_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = "${100 + count.index}"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = "${local.cyhy_trusted_ingress_ports[count.index]}"
  to_port = "${local.cyhy_trusted_ingress_ports[count.index]}"
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ephemeral_ports" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.cyhy_public_acl.id}"
  egress = false
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${120 + count.index}"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow all ICMP traffic to ingress, since we're scanning and will
# want ping responses, etc.
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_icmp" {
  network_acl_id = "${aws_network_acl.cyhy_public_acl.id}"
  egress = false
  protocol = "icmp"
  rule_number = 135
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  icmp_type = -1
  icmp_code = -1
}

# Allow egress to anywhere via any protocol and port, since we're
# scanning
resource "aws_network_acl_rule" "public_egress_to_anywhere_via_any_port" {
  network_acl_id = "${aws_network_acl.cyhy_public_acl.id}"
  egress = true
  protocol = "-1"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 0
}

# Allow https ingress from private subnet, needed for outbound https from
# private subnet, which goes through the NAT GW (resides in public subnet)
resource "aws_network_acl_rule" "public_ingress_from_private_via_https" {
  network_acl_id = "${aws_network_acl.cyhy_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_private_subnet.cidr_block}"
  from_port = 443
  to_port = 443
}

# Allow ingress from scanner subnet on any protocol and port, needed for
# outbound scans from scanner subnet, which go through the
# NAT GW (resides in public subnet)
resource "aws_network_acl_rule" "public_ingress_from_scanner_via_any_port" {
  network_acl_id = "${aws_network_acl.cyhy_public_acl.id}"
  egress = false
  protocol = "-1"
  rule_number = 160
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 0
  to_port = 0
}
