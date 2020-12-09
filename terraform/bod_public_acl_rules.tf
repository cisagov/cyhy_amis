# Allow ingress from the docker subnet via HTTP (for downloading the
# public suffix list), HTTPS (for AWS CLI), FTP (for downloading ASN
# information).  This allows EC2 instances in the docker subnet to
# send the traffic they want via the NAT gateway, subject to their own
# security group and network ACL restrictions.
resource "aws_network_acl_rule" "bod_public_ingress_from_docker" {
  count = length(local.bod_docker_egress_anywhere_ports)

  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 80 + count.index
  rule_action    = "allow"
  cidr_block     = aws_subnet.bod_docker_subnet.cidr_block
  from_port      = local.bod_docker_egress_anywhere_ports[count.index]
  to_port        = local.bod_docker_egress_anywhere_ports[count.index]
}

# Allow ingress from the lambda subnet via HTTP and HTTPS (for pshtt),
# as well as SMTP (for trustymail).  This allows EC2 instances in the
# lambda subnet to send the traffic they want via the NAT gateway,
# subject to their own security group and network ACL restrictions.
resource "aws_network_acl_rule" "bod_public_ingress_from_lambda" {
  count = length(local.bod_lambda_egress_anywhere_ports)

  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 100 + count.index
  rule_action    = "allow"
  cidr_block     = aws_subnet.bod_lambda_subnet.cidr_block
  from_port      = local.bod_lambda_egress_anywhere_ports[count.index]
  to_port        = local.bod_lambda_egress_anywhere_ports[count.index]
}

# Allow ingress from anywhere via ephemeral ports.  This is necessary
# because the return traffic to the NAT gateway has to enter here
# before it is relayed to the private subnet.
resource "aws_network_acl_rule" "bod_public_ingress_from_anywhere_via_ephemeral_ports" {
  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 120
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow ingress from anywhere via ssh
resource "aws_network_acl_rule" "bod_public_ingress_from_anywhere_via_ssh" {
  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = false
  protocol       = "tcp"
  rule_number    = 140
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Allow egress to the docker subnet via ssh
resource "aws_network_acl_rule" "bod_public_egress_to_docker_via_ssh" {
  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 150
  rule_action    = "allow"
  cidr_block     = aws_subnet.bod_docker_subnet.cidr_block
  from_port      = 22
  to_port        = 22
}

# Allow egress to the bastion via ssh.  This is necessary because
# Ansible applies the ssh proxy even when sshing to the bastion.
resource "aws_network_acl_rule" "bod_public_egress_to_bastion_via_ssh" {
  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 160
  rule_action    = "allow"
  cidr_block     = "${aws_instance.bod_bastion.public_ip}/32"
  from_port      = 22
  to_port        = 22
}

# Allow egress anywhere via HTTP (for downloading the public suffix
# list and pshtt), HTTPS (for AWS CLI and pshtt), SMTP (for
# trustymail), and FTP (for downloading ASN information).  This is so
# the NAT gateway can relay the corresponding requests from the
# private subnet.
resource "aws_network_acl_rule" "bod_public_egress_anywhere" {
  count = length(
    distinct(
      concat(
        local.bod_docker_egress_anywhere_ports,
        local.bod_lambda_egress_anywhere_ports,
      ),
    ),
  )

  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 170 + count.index
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port = element(
    distinct(
      concat(
        local.bod_docker_egress_anywhere_ports,
        local.bod_lambda_egress_anywhere_ports,
      ),
    ),
    count.index,
  )
  to_port = element(
    distinct(
      concat(
        local.bod_docker_egress_anywhere_ports,
        local.bod_lambda_egress_anywhere_ports,
      ),
    ),
    count.index,
  )
}

# Allow egress to anywhere via ephemeral ports
resource "aws_network_acl_rule" "bod_public_egress_to_anywhere_via_ephemeral_ports" {
  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = true
  protocol       = "tcp"
  rule_number    = 200
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow all ports and protocols from Management private subnet to ingress,
# for internal scanning
resource "aws_network_acl_rule" "bod_public_ingress_all_from_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.bod_public_acl.id
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
resource "aws_network_acl_rule" "bod_public_egress_all_to_mgmt_private" {
  count = var.enable_mgmt_vpc ? 1 : 0

  network_acl_id = aws_network_acl.bod_public_acl.id
  egress         = true
  protocol       = "-1"
  rule_number    = 201
  rule_action    = "allow"
  cidr_block     = aws_subnet.mgmt_private_subnet[0].cidr_block
  from_port      = 0
  to_port        = 0
}
