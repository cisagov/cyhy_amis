# The CyHy Nessus VPC
resource "aws_vpc" "nessus_vpc" {
  cidr_block = "10.10.10.0/23"

  tags = "${merge(var.tags, map("Name", "CyHy Nessus"))}"
}

# Scanner subnet of the VPC
resource "aws_subnet" "nessus_scanner_subnet" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"
  cidr_block = "10.10.11.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [
    "aws_internet_gateway.nessus_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners"))}"
}

# Elastic IP for the NAT gateway
resource "aws_eip" "nessus_eip" {
  vpc = true

  depends_on = [
    "aws_internet_gateway.nessus_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Nessus NATGW IP"))}"
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "nessus_nat_gw" {
  allocation_id = "${aws_eip.nessus_eip.id}"
  subnet_id = "${aws_subnet.nessus_scanner_subnet.id}"

  depends_on = [
    "aws_internet_gateway.nessus_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Nessus NATGW"))}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "nessus_igw" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Nessus IGW"))}"
}

# Default route table, which routes all external traffic through the
# NAT gateway
resource "aws_default_route_table" "nessus_default_route_table" {
  default_route_table_id = "${aws_vpc.nessus_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "CyHy Nessus NATGW"))}"
}

# Route all external traffic through the NAT gateway
resource "aws_route" "route_external_traffic_through_nat_gateway" {
  route_table_id = "${aws_default_route_table.nessus_default_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nessus_nat_gw.id}"
}

# Route table for our scanner subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "nessus_scanner_route_table" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners IGW"))}"
}

# Route all external traffic through the internet gateway
resource "aws_route" "route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.nessus_scanner_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.nessus_igw.id}"
}

# Associate the route table with the scanner subnet
resource "aws_route_table_association" "association" {
  subnet_id = "${aws_subnet.nessus_scanner_subnet.id}"
  route_table_id = "${aws_route_table.nessus_scanner_route_table.id}"
}

# ACL for the scanner subnet of the VPC
resource "aws_network_acl" "nessus_scanner_acl" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"
  subnet_ids = [
    "${aws_subnet.nessus_scanner_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners"))}"
}

# Allow ssh ingress from anywhere
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_ssh" {
  network_acl_id = "${aws_network_acl.nessus_scanner_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = "${aws_network_acl.nessus_scanner_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "scanner_ingress_from_anywhere_via_ephemeral_ports_udp" {
  network_acl_id = "${aws_network_acl.nessus_scanner_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow egress to anywhere via all ports and protocols
resource "aws_network_acl_rule" "scanner_egress_to_anywhere_via_any_port" {
  network_acl_id = "${aws_network_acl.nessus_scanner_acl.id}"
  egress = true
  protocol = "-1"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 0
}

# Security group for the scanner portion of the VPC
resource "aws_security_group" "nessus_scanner_sg" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners"))}"
}

# Allow ingress from anywhere via ssh
resource "aws_security_group_rule" "scanner_ingress_anywhere_via_ssh" {
  security_group_id = "${aws_security_group.nessus_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 22
  to_port = 22
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_security_group_rule" "scanner_ingress_anywhere_via_ephemeral_ports_tcp" {
  security_group_id = "${aws_security_group.nessus_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}
resource "aws_security_group_rule" "scanner_ingress_anywhere_via_ephemeral_ports_udp" {
  security_group_id = "${aws_security_group.nessus_scanner_sg.id}"
  type = "ingress"
  protocol = "udp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}

# Allow egress on all ports and protocols to anywhere
resource "aws_security_group_rule" "scanner_egress_anywhere_any_port" {
  security_group_id = "${aws_security_group.nessus_scanner_sg.id}"
  type = "egress"
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 0
  to_port = 0
}
