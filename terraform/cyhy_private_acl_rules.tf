# Allow egress to the both scanner subnets via ssh
resource "aws_network_acl_rule" "private_egress_to_portscanner_via_ssh" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 100
  rule_action    = "allow"
  cidr_block     = aws_subnet.cyhy_portscanner_subnet.cidr_block
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "private_egress_to_vulnscanner_via_ssh" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 101
  rule_action    = "allow"
  cidr_block     = aws_subnet.cyhy_vulnscanner_subnet.cidr_block
  from_port      = 22
  to_port        = 22
}

# Allow egress to the mongo host via the MongoDB port
resource "aws_network_acl_rule" "private_egress_to_mongo_via_mongo" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 102
  rule_action    = "allow"
  cidr_block     = "${aws_instance.cyhy_mongo[0].private_ip}/32"
  from_port      = 27017
  to_port        = 27017
}

# Allow egress anywhere via https
# Needed to pull files from GitHub and external data sources (e.g. usgs.gov)
resource "aws_network_acl_rule" "cyhy_private_egress_anywhere_via_https" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 103
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow ingress from anywhere via ephemeral ports
# Note: includes ingress from the BOD 18-01 private subnet via mongodb
resource "aws_network_acl_rule" "private_ingress_from_anywhere_via_ephemeral_ports" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 104
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow ingress from the bastion via ssh
resource "aws_network_acl_rule" "private_ingress_from_bastion_via_ssh" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 110
  rule_action    = "allow"
  cidr_block     = "${aws_instance.cyhy_bastion.private_ip}/32"
  from_port      = 22
  to_port        = 22
}

# Allow egress to the bastion via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_bastion_via_ephemeral_ports" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 111
  rule_action    = "allow"
  cidr_block     = "${aws_instance.cyhy_bastion.private_ip}/32"
  from_port      = 1024
  to_port        = 65535
}

# Allow egress to the BOD 18-01 docker subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_bod_docker_via_ephemeral_ports" {
  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 120
  rule_action    = "allow"
  cidr_block     = aws_subnet.bod_docker_subnet.cidr_block
  from_port      = 1024
  to_port        = 65535
}

# Allow all ports and protocols from Management private subnet to ingress,
# for internal scanning
resource "aws_network_acl_rule" "cyhy_private_ingress_all_from_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.cyhy_private_acl.id
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
resource "aws_network_acl_rule" "cyhy_private_egress_all_to_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.cyhy_private_acl.id
  egress         = true
  protocol       = "-1"
  rule_number    = 201
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 0
  to_port        = 0
}
