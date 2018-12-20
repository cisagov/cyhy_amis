# Allow ingress via ephemeral ports from anywhere via TCP
resource "aws_network_acl_rule" "lambda_ingress_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = "${aws_network_acl.bod_lambda_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 110
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow ingress via ephemeral ports from Google DNS via UDP
resource "aws_network_acl_rule" "lambda_ingress_from_google_dns_via_ephemeral_ports_udp_1" {
  network_acl_id = "${aws_network_acl.bod_lambda_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 111
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "lambda_ingress_from_google_dns_via_ephemeral_ports_udp_2" {
  network_acl_id = "${aws_network_acl.bod_lambda_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 112
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 1024
  to_port = 65535
}

# Allow outbound HTTP, HTTPS, and SMTP (25, 467, 587) anywhere
resource "aws_network_acl_rule" "lambda_egress_anywhere" {
  count = "${length(local.bod_lambda_egress_anywhere_ports)}"

  network_acl_id = "${aws_network_acl.bod_lambda_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = "${120 + count.index}"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = "${local.bod_lambda_egress_anywhere_ports[count.index]}"
  to_port = "${local.bod_lambda_egress_anywhere_ports[count.index]}"
}

# Allow egress to Google DNS
resource "aws_network_acl_rule" "lambda_egress_to_google_dns_1" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_lambda_acl.id}"
  egress = true
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${135 + count.index}"
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "lambda_egress_to_google_dns_2" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_lambda_acl.id}"
  egress = true
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${137 + count.index}"
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 53
  to_port = 53
}
