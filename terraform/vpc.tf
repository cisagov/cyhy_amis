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

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.cyhy_nat_gw.id}"
  }

  tags = "${merge(var.tags, map("Name", "CyHy NATGW"))}"
}

# Route table for our scanner subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "cyhy_scanner_route_table" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cyhy_igw.id}"
  }

  tags = "${merge(var.tags, map("Name", "CyHy Scanners IGW"))}"
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

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # Allow inbound SSH traffic from scanner subnet
  # Needed for commander to talk to scanners
  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
    from_port = 22
    to_port = 22
  }

  # Allow outbound SSH to scanner subnet
  # Needed for commander to talk to scanners
  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
    from_port = 22
    to_port = 22
  }

  # Allow outbound on ephemeral ports to scanner subnet
  # Needed for commander to talk to scanners
  egress {
    protocol = "tcp"
    rule_no = 130
    action = "allow"
    cidr_block = "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
    from_port = 1024
    to_port = 65535
  }

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# ACL for the scanner subnet of the VPC
resource "aws_network_acl" "cyhy_scanner_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_scanner_subnet.id}"
  ]

  # Allow Nessus port inbound from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 8834
    to_port = 8834
  }

  # Allow SSH in from anywhere to the scanner subnet
  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  # Allow egress on all ports and protocols to anywhere
  egress {
    protocol = "-1"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

# Security group for the private portion of the VPC
resource "aws_security_group" "cyhy_private_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  # Allow SSH ingress from the scanner subnet
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow SSH egress to the scanner subnet
  egress {
    protocol = "tcp"
    cidr_blocks = [
     "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow SSH egress to anywhere
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Security group for the scanner portion of the VPC
resource "aws_security_group" "cyhy_scanner_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  # Allow Nessus port from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8834
    to_port = 8834
  }

  # Allow SSH ingress from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
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

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

# Security group for the bastion host
resource "aws_security_group" "cyhy_bastion_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  # Allow SSH ingress from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  # Allow SSH egress to the scanner subnet
  egress {
    protocol = "tcp"
    cidr_blocks = [
     "${aws_subnet.cyhy_scanner_subnet.cidr_block}"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow egress on all ephemeral ports
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  tags = "${merge(var.tags, map("Name", "CyHy Bastion"))}"
}
