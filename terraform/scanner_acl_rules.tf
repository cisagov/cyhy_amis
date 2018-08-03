# Allow ingress from anywhere via the Nessus UI port
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_nessus" {
  network_acl_id = "${aws_network_acl.cyhy_scanner_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 8834
  to_port = 8834
}

# Allow ingress from anywhere via ssh
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_scanner_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 110
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = "${aws_network_acl.cyhy_scanner_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_ephemeral_ports_udp" {
  network_acl_id = "${aws_network_acl.cyhy_scanner_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow egress to anywhere via any protocol and port
resource "aws_network_acl_rule" "scanner_egress_to_anywhere_via_any_port" {
  network_acl_id = "${aws_network_acl.cyhy_scanner_acl.id}"
  egress = true
  protocol = "-1"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 0
}
