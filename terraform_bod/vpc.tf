# The BOD 18-01 VPC
resource "aws_vpc" "bod_vpc" {
  cidr_block = "10.10.12.0/23"

  tags = "${merge(var.tags, map("Name", "BOD 18-01"))}"
}

# Private subnet of the VPC
resource "aws_subnet" "bod_private_subnet" {
 vpc_id = "${aws_vpc.bod_vpc.id}"
 cidr_block = "10.10.12.0/24"
 availability_zone = "${var.aws_region}${var.aws_availability_zone}"

 depends_on = [
   "aws_internet_gateway.bod_igw"
 ]

 tags = "${merge(var.tags, map("Name", "BOD 18-01 Private"))}"
}

# Public subnet of the VPC
resource "aws_subnet" "bod_public_subnet" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  cidr_block = "10.10.13.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [
    "aws_internet_gateway.bod_igw"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Public"))}"
}

# Elastic IP for the NAT gateway
resource "aws_eip" "bod_eip" {
  vpc = true

  depends_on = [
    "aws_internet_gateway.bod_igw"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 NATGW IP"))}"
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "bod_nat_gw" {
  allocation_id = "${aws_eip.bod_eip.id}"
  subnet_id = "${aws_subnet.bod_public_subnet.id}"

  depends_on = [
    "aws_internet_gateway.bod_igw"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 NATGW"))}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "bod_igw" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 IGW"))}"
}

# Default route table, which routes all external traffic through the
# NAT gateway
resource "aws_default_route_table" "bod_default_route_table" {
  default_route_table_id = "${aws_vpc.bod_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.bod_nat_gw.id}"
  }

  tags = "${merge(var.tags, map("Name", "BOD 18-01 default route table"))}"
}

# Route table for our public subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "bod_public_route_table" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.bod_igw.id}"
  }

  tags = "${merge(var.tags, map("Name", "BOD 18-01 public route table"))}"
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "association" {
  subnet_id = "${aws_subnet.bod_public_subnet.id}"
  route_table_id = "${aws_route_table.bod_public_route_table.id}"
}

# ACL for the private subnet of the VPC
resource "aws_network_acl" "bod_private_acl" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  subnet_ids = [
    "${aws_subnet.bod_private_subnet.id}"
  ]

  # Allow inbound SSH traffic from public subnet
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
    from_port = 22
    to_port = 22
  }

  # Allow ephemeral ports from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # Allow outbound on ephemeral ports to public subnet
  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
    from_port = 1024
    to_port = 65535
  }

  # Allow outbound HTTP and HTTPS
  egress {
    protocol = "tcp"
    rule_no = 130
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }
  egress {
    protocol = "tcp"
    rule_no = 131
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  # Allow outbound SMTP
  egress {
    protocol = "tcp"
    rule_no = 140
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 25
    to_port = 25
  }
  egress {
    protocol = "tcp"
    rule_no = 141
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 465
    to_port = 465
  }
  egress {
    protocol = "tcp"
    rule_no = 142
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 587
    to_port = 587
  }

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Private"))}"
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "bod_public_acl" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  subnet_ids = [
    "${aws_subnet.bod_public_subnet.id}"
  ]

  # Allow SSH in from anywhere to the public subnet
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
  }

  # Allow ephemeral ports from the public subnet
  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
    from_port = 1025
    to_port = 65535
  }

  # Allow SSH to the private subnet
  egress {
    protocol = "tcp"
    rule_no = 140
    action = "allow"
    cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
    from_port = 22
    to_port = 22
  }

  # Allow egress on ephemeral ports to anywhere
  egress {
    protocol = "tcp"
    rule_no = 150
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1025
    to_port = 65535
  }

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Public"))}"
}

# Security group for the private portion of the VPC
resource "aws_security_group" "bod_private_sg" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  # Allow SSH ingress from the public subnet
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "${aws_subnet.bod_public_subnet.cidr_block}"
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

  # Allow ephemeral ports to the public subnet
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.bod_public_subnet.cidr_block}"
    ]
    from_port = 1024
    to_port = 65535
  }

  # Allow HTTP and HTTPS egress anywhere
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port = 80
  }
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    to_port = 443
  }

  # Allow SMTP egress anywhere
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 25
    to_port = 25
  }
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 465
    to_port = 465
  }
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 587
    to_port = 587
  }

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Private"))}"
}

# Security group for the public portion of the VPC
resource "aws_security_group" "bod_public_sg" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  # Allow SSH ingress from anywhere
  ingress {
    protocol = "tcp"
    cidr_blocks = [
     "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow ephemeral ports from the private subnet
  ingress {
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.bod_private_subnet.cidr_block}"
    ]
    from_port = 1024
    to_port = 65535
  }

  # Allow SSH to the private subnet
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.bod_private_subnet.cidr_block}"
    ]
    from_port = 22
    to_port = 22
  }

  # Allow egress on all ephemeral ports to anywhere
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Public"))}"
}
