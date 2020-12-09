# Allow ingress from trusted networks via the Nessus UI port
resource "aws_security_group_rule" "ingress_from_trusted_via_nessus" {
  security_group_id = aws_security_group.nessus_scanner_sg.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_ingress_networks_ipv4

  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = 8834
  to_port   = 8834
}

# Allow ingress from trusted networks via ssh
resource "aws_security_group_rule" "ingress_from_trusted_via_ssh" {
  security_group_id = aws_security_group.nessus_scanner_sg.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_ingress_networks_ipv4

  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = 22
  to_port   = 22
}

# Allow egress anywhere via all ports and protocols, since we're
# scanning
resource "aws_security_group_rule" "egress_anywhere" {
  security_group_id = aws_security_group.nessus_scanner_sg.id
  type              = "egress"
  protocol          = "-1"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port = 0
  to_port   = 0
}
