# Allow ssh ingress from the public subnet
resource "aws_network_acl_rule" "docker_ingress_from_public_via_ssh" {
  network_acl_id = aws_network_acl.bod_docker_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = aws_subnet.bod_public_subnet.cidr_block
  from_port      = 22
  to_port        = 22
}

# Allow ingress via ephemeral ports from anywhere via TCP
resource "aws_network_acl_rule" "docker_ingress_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = aws_network_acl.bod_docker_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 110
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow outbound HTTP, HTTPS, and FTP anywhere
resource "aws_network_acl_rule" "docker_egress_anywhere" {
  count = length(local.bod_docker_egress_anywhere_ports)

  network_acl_id = aws_network_acl.bod_docker_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 120 + count.index
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = local.bod_docker_egress_anywhere_ports[count.index]
  to_port        = local.bod_docker_egress_anywhere_ports[count.index]
}

# Allow egress anywhere via ephemeral ports.  We could get away with
# restricting this to the public subnet, except that FTP in passive
# mode needs to be able to reach out anywhere.
#
# Note that this rule allows egress to the CyHy private subnet as
# well.
resource "aws_network_acl_rule" "docker_egress_to_public_via_ephemeral_ports" {
  network_acl_id = aws_network_acl.bod_docker_acl.id
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
resource "aws_network_acl_rule" "bod_private_ingress_all_from_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.bod_docker_acl.id
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
resource "aws_network_acl_rule" "bod_private_egress_all_to_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.bod_docker_acl.id
  egress         = true
  protocol       = "-1"
  rule_number    = 201
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 0
  to_port        = 0
}
