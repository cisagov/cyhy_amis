# The CyHy VPC
resource "aws_vpc" "cyhy_vpc" {
  cidr_block = "10.10.10.0/23"

  tags = "${merge(var.tags, map("Name", "CyHy"))}"
}

# Private subnet of the VPC, for database and CyHy commander
resource "aws_subnet" "cyhy_private_subnet" {
 vpc_id = "${aws_vpc.cyhy_vpc.id}"
 cidr_block = "10.10.10.0/24"
 availability_zone = "${var.aws_region}${var.aws_availability_zone}"

 depends_on = [
   "aws_internet_gateway.cyhy_igw"
 ]

 tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Scanner subnet of the VPC
resource "aws_subnet" "cyhy_scanner_subnet" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  cidr_block = "10.10.11.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

# Elastic IP for the NAT gateway
resource "aws_eip" "cyhy_eip" {
  vpc = true

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy NATGW IP"))}"
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "cyhy_nat_gw" {
  allocation_id = "${aws_eip.cyhy_eip.id}"
  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy NATGW"))}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "cyhy_igw" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy IGW"))}"
}

# Default route table, which routes all external traffic through the
# NAT gateway
resource "aws_default_route_table" "cyhy_default_route_table" {
  default_route_table_id = "${aws_vpc.cyhy_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "CyHy NATGW"))}"
}

# Route all external traffic through the NAT gateway
resource "aws_route" "route_external_traffic_through_nat_gateway" {
  route_table_id = "${aws_default_route_table.cyhy_default_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.cyhy_nat_gw.id}"
}

# Route table for our scanner subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "cyhy_scanner_route_table" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Scanners IGW"))}"
}

# Route all external traffic through the internet gateway
resource "aws_route" "route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.cyhy_scanner_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.cyhy_igw.id}"
}

# Associate the route table with the scanner subnet
resource "aws_route_table_association" "association" {
  subnet_id = "${aws_subnet.cyhy_scanner_subnet.id}"
  route_table_id = "${aws_route_table.cyhy_scanner_route_table.id}"
}

# ACL for the private subnet of the VPC
resource "aws_network_acl" "cyhy_private_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_private_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Allow ingress from scanner subnet via ephemeral ports
resource "aws_network_acl_rule" "private_ingress_from_scanner_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}

# Allow ingress from the scanner subnet via ssh
resource "aws_network_acl_rule" "private_ingress_from_scanner_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 110
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress to the scanner subnet via ssh
resource "aws_network_acl_rule" "private_egress_to_scanner_via_ssh" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress to the scanner subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_scanner_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.cyhy_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}

# ACL for the scanner subnet of the VPC
resource "aws_network_acl" "cyhy_scanner_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_scanner_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

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

# Security group for the private portion of the VPC
resource "aws_security_group" "cyhy_private_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Allow ingress via ephemeral ports from anywhere
resource "aws_security_group_rule" "private_ingress_from_anywhere_via_ephemeral_ports" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}

# Allow SSH ingress from the scanner security group
resource "aws_security_group_rule" "private_ssh_ingress_from_scanner" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow SSH egress to the scanner security group
resource "aws_security_group_rule" "private_ssh_egress_to_scanner" {
  security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  from_port = 22
  to_port = 22
}

# Security group for the scanner portion of the VPC
resource "aws_security_group" "cyhy_scanner_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

# Allow ingress from anywhere via the Nessus UI port
resource "aws_security_group_rule" "scanner_ingress_anywhere_via_nessus" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 8834
  to_port = 8834
}

# Allow ingress from anywhere via ssh
resource "aws_security_group_rule" "scanner_ingress_anywhere_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 22
  to_port = 22
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_security_group_rule" "scanner_ingress_anywhere_tcp" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}
resource "aws_security_group_rule" "scanner_ingress_anywhere_udp" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "udp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}

# Allow ingress via ssh from the private security group
resource "aws_security_group_rule" "scanner_ingress_from_private_sg_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow egress anywhere via all ports and protocols
resource "aws_security_group_rule" "scanner_egress_anywhere" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "egress"
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 0
  to_port = 0
}

# Allow egress via ssh to the private security group
resource "aws_security_group_rule" "scanner_egress_to_private_sg_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  from_port = 22
  to_port = 22
}
