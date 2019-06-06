# Allow ingress from public mgmt subnet (bastion) via the Nessus UI and ssh ports
resource "aws_network_acl_rule" "mgmt_private_ingress_from_public_via_nessus_and_ssh" {
  count = var.enable_mgmt_vpc * length(local.mgmt_trusted_ingress_ports)

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = false
  protocol       = "tcp"
  rule_number    = 100 + count.index
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_public_subnet[0].cidr_block
  from_port      = local.mgmt_trusted_ingress_ports[count.index]
  to_port        = local.mgmt_trusted_ingress_ports[count.index]
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_network_acl_rule" "mgmt_private_ingress_from_anywhere_via_ephemeral_ports" {
  count = var.enable_mgmt_vpc * length(local.tcp_and_udp)

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = false
  protocol       = local.tcp_and_udp[count.index]
  rule_number    = 120 + count.index
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow ICMP traffic from CyHy VPC to ingress, since we're scanning and will
# want ping responses, etc.
resource "aws_network_acl_rule" "mgmt_private_ingress_from_cyhy_vpc_via_icmp" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = false
  protocol       = "icmp"
  rule_number    = 135
  rule_action    = "allow"
  cidr_block     = aws_vpc.cyhy_vpc.cidr_block
  icmp_type      = -1
  icmp_code      = -1
}

# Allow ICMP traffic from BOD 18-01 VPC to ingress, since we're scanning and
# will want ping responses, etc.
resource "aws_network_acl_rule" "mgmt_private_ingress_from_bod_vpc_via_icmp" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = false
  protocol       = "icmp"
  rule_number    = 136
  rule_action    = "allow"
  cidr_block     = aws_vpc.bod_vpc.cidr_block
  icmp_type      = -1
  icmp_code      = -1
}

# Allow ICMP traffic from Management public subnet to ingress, since we're
# scanning and will want ping responses, etc.
resource "aws_network_acl_rule" "mgmt_private_ingress_from_mgmt_public_via_icmp" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = false
  protocol       = "icmp"
  rule_number    = 137
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_public_subnet[0].cidr_block
  icmp_type      = -1
  icmp_code      = -1
}

# Allow egress anywhere via https
# Needed for Nessus plugin updates
resource "aws_network_acl_rule" "mgmt_private_egress_anywhere_via_https" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 140
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow egress to CyHy VPC via any protocol and port
# Needed for vulnerability scanning of the CyHy VPC
resource "aws_network_acl_rule" "mgmt_private_egress_to_cyhy_vpc_via_any_port" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = true
  protocol       = "-1"
  rule_number    = 150
  rule_action    = "allow"
  cidr_block     = aws_vpc.cyhy_vpc.cidr_block
  from_port      = 0
  to_port        = 0
}

# Allow egress to BOD 18-01 VPC via any protocol and port
# Needed for vulnerability scanning of the BOD 18-01 VPC
resource "aws_network_acl_rule" "mgmt_private_egress_to_bod_vpc_via_any_port" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = true
  protocol       = "-1"
  rule_number    = 151
  rule_action    = "allow"
  cidr_block     = aws_vpc.bod_vpc.cidr_block
  from_port      = 0
  to_port        = 0
}

# Allow egress to Management public subnet via any protocol and port
# Needed for vulnerability scanning of the Management public subnet
resource "aws_network_acl_rule" "mgmt_private_egress_to_mgmt_public_via_any_port" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = true
  protocol       = "-1"
  rule_number    = 152
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_public_subnet[0].cidr_block
  from_port      = 0
  to_port        = 0
}

# Allow egress to the bastion via ephemeral ports
resource "aws_network_acl_rule" "mgmt_private_egress_to_bastion_via_ephemeral_ports" {
  count = var.enable_mgmt_vpc

  network_acl_id = aws_network_acl.mgmt_private_acl[0].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 160
  rule_action    = "allow"
  cidr_block     = "${aws_instance.mgmt_bastion[0].private_ip}/32"
  from_port      = 1024
  to_port        = 65535
}

