# The VPC within which we launch the Mongo instance
resource "aws_vpc" "mongo_vpc" {
  cidr_block = "10.65.66.0/24"

  tags = "${var.tags}"
}

# Public subnet of the VPC
resource "aws_subnet" "mongo_public_subnet" {
  vpc_id = "${aws_vpc.mongo_vpc.id}"
  cidr_block = "10.65.66.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [
    "aws_internet_gateway.mongo_igw"
  ]

  tags = "${var.tags}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "mongo_igw" {
  vpc_id = "${aws_vpc.mongo_vpc.id}"

  tags = "${var.tags}"
}

# Default route table, which routes all external traffic through the
# internet gateway
resource "aws_default_route_table" "mongo_default_route_table" {
  default_route_table_id = "${aws_vpc.mongo_vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mongo_igw.id}"
  }

  tags = "${var.tags}"
}

# ACL for the public-facing subnet of the VPC
resource "aws_network_acl" "mongo_public_acl" {
  vpc_id = "${aws_vpc.mongo_vpc.id}"
  subnet_ids = [
    "${aws_subnet.mongo_public_subnet.id}"
  ]

  # Allow ssh access from anywhere
  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
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

  # Allow HTTP (needed for apt-get)
  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  # Allow HTTPS
  egress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  # Allow egress to anywhere via ephemeral ports
  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  tags = "${var.tags}"
}

# Security group for the public portion of the VPC
resource "aws_security_group" "mongo_public_sg" {
  vpc_id = "${aws_vpc.mongo_vpc.id}"

  # Allow ssh access from anywhere
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

  # Allow HTTP (needed for apt-get)
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port = 80
  }

  # Allow HTTPS
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 443
    to_port = 443
  }

  # Allow egress to anywhere via ephemeral ports
  egress {
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 1024
    to_port = 65535
  }

  tags = "${var.tags}"
}
