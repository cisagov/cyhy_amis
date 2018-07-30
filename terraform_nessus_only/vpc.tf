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

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nessus_nat_gw.id}"
  }

  tags = "${merge(var.tags, map("Name", "CyHy Nessus NATGW"))}"
}

# Route table for our scanner subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "nessus_scanner_route_table" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.nessus_igw.id}"
  }

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners IGW"))}"
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

  # Allow SSH in from anywhere to the scanner subnet
  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  # Allow ingress from TCP ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }
   # Allow ingress from UDP ephemeral ports from anywhere
  ingress {
    protocol = "udp"
    rule_no = 130
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # Allow egress on all ports and protocols to anywhere
  egress {
    protocol = "-1"
    rule_no = 140
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners"))}"
}

# Security group for the scanner portion of the VPC
resource "aws_security_group" "nessus_scanner_sg" {
  vpc_id = "${aws_vpc.nessus_vpc.id}"

  # Allow SSH ingress from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow TCP ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }
   # Allow UDP ephemeral ports from anywhere
  ingress {
    protocol = "udp"
    cidr_blocks = [
     "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  # Allow egress on all ports and protocols to anywhere
  egress {
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port = 0
  }

  tags = "${merge(var.tags, map("Name", "CyHy Nessus Scanners"))}"
}
