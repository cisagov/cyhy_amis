# Deny ingress from anywhere via TCP ports 0-21
resource "aws_network_acl_rule" "scanner_deny_ingress_from_anywhere_tcp_ports_0_to_21" {
  network_acl_id = aws_network_acl.nessus_scanner_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 100
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1
  to_port        = 21
}

# Deny ingress from anywhere via TCP ports 23-1023
resource "aws_network_acl_rule" "scanner_deny_ingress_from_anywhere_tcp_ports_23_to_1023" {
  network_acl_id = aws_network_acl.nessus_scanner_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 110
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 23
  to_port        = 1023
}

# Deny ingress from anywhere via UDP ports 0-1023
resource "aws_network_acl_rule" "scanner_deny_ingress_from_anywhere_udp_ports_0_to_1023" {
  network_acl_id = aws_network_acl.nessus_scanner_acl.id
  egress         = false
  protocol       = "udp"
  rule_number    = 120
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 1023
}

# Allow ingress from anywhere via any protocol and port, since we're scanning
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_any_port" {
  network_acl_id = aws_network_acl.nessus_scanner_acl.id
  egress         = false
  protocol       = "-1"
  rule_number    = 130
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Allow egress to anywhere via any protocol and port, since we're scanning
resource "aws_network_acl_rule" "scanner_egress_to_anywhere_via_any_port" {
  network_acl_id = aws_network_acl.nessus_scanner_acl.id
  egress         = true
  protocol       = "-1"
  rule_number    = 140
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
