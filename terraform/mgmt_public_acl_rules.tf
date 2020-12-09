# Allow ingress from the private subnet via HTTPS (for Nessus plugin updates)
# and DNS (for Google DNS).
# This allows EC2 instances in the private subnet to send the traffic
# they want via the NAT gateway, subject to their own security group
# and network ACL restrictions.
resource "aws_network_acl_rule" "mgmt_public_ingress_from_private" {
  count = var.enable_mgmt_vpc ? length(local.mgmt_scanner_egress_anywhere_ports) : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = false
  protocol       = "tcp"
  rule_number    = 80 + count.index
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = local.mgmt_scanner_egress_anywhere_ports[count.index]
  to_port        = local.mgmt_scanner_egress_anywhere_ports[count.index]
}

resource "aws_network_acl_rule" "mgmt_public_ingress_from_private_via_port_53" {
  count = var.enable_mgmt_vpc ? length(local.tcp_and_udp) : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = false
  protocol       = local.tcp_and_udp[count.index]
  rule_number    = 85 + count.index
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 53
  to_port        = 53
}

# Allow ingress from anywhere via ephemeral ports for TCP.  This is
# necessary because the return traffic to the NAT gateway has to enter
# here before it is relayed to the private subnet.
resource "aws_network_acl_rule" "mgmt_public_ingress_from_anywhere_via_ephemeral_ports_tcp" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = false
  protocol       = "tcp"
  rule_number    = 90
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow ingress from anywhere via ssh
resource "aws_network_acl_rule" "mgmt_public_ingress_from_anywhere_via_ssh" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = false
  protocol       = "tcp"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Allow egress to the private subnet via ssh
resource "aws_network_acl_rule" "mgmt_public_egress_to_private_via_ssh" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 110
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 22
  to_port        = 22
}

# Allow egress to the bastion via ssh.  This is necessary because
# Ansible applies the ssh proxy even when sshing to the bastion.
resource "aws_network_acl_rule" "mgmt_public_egress_to_bastion_via_ssh" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 120
  rule_action    = "allow"
  cidr_block     = "${aws_instance.mgmt_bastion[0].public_ip}/32"
  from_port      = 22
  to_port        = 22
}

# Allow egress anywhere via HTTPS (for Nessus plugin updates).
# This is so the NAT gateway can relay the corresponding requests
# from the private subnet.
resource "aws_network_acl_rule" "mgmt_public_egress_anywhere" {
  count = var.enable_mgmt_vpc ? length(local.mgmt_scanner_egress_anywhere_ports) : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 129 + count.index
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = local.mgmt_scanner_egress_anywhere_ports[count.index]
  to_port        = local.mgmt_scanner_egress_anywhere_ports[count.index]
}

# Allow egress to anywhere via TCP ephemeral ports
resource "aws_network_acl_rule" "mgmt_public_egress_to_anywhere_via_tcp_ephemeral_ports" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = true
  protocol       = "tcp"
  rule_number    = 140
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow all ports and protocols from Management private subnet to ingress,
# for internal scanning
resource "aws_network_acl_rule" "mgmt_public_ingress_all_from_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = false
  protocol       = "-1"
  rule_number    = 200
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 0
  to_port        = 0
}

# Allow all ports and protocols to egress to Management private subnet,
# for internal scanning
resource "aws_network_acl_rule" "mgmt_public_egress_all_to_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.mgmt_public_acl[0].id
  egress         = true
  protocol       = "-1"
  rule_number    = 201
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 0
  to_port        = 0
}
