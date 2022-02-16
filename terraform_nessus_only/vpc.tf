# Use the default VPC for our region
resource "aws_default_vpc" "default" {
  tags = { Name = "Default VPC" }
}

# VPC subnet for Nessus scanner
resource "aws_subnet" "nessus_scanner_subnet" {
  vpc_id = aws_default_vpc.default.id

  cidr_block        = "172.31.192.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  tags = { "Name" = "Manual CyHy Nessus Scanners" }
}

# ACL for the Nessus scanner subnet of the VPC
resource "aws_network_acl" "nessus_scanner_acl" {
  vpc_id = aws_default_vpc.default.id

  subnet_ids = [
    aws_subnet.nessus_scanner_subnet.id,
  ]

  tags = { "Name" = "Manual CyHy Nessus Scanners" }
}

# Security group for the Nessus scanner
resource "aws_security_group" "nessus_scanner_sg" {
  vpc_id = aws_default_vpc.default.id

  tags = { "Name" = "Manual CyHy Nessus Scanners" }
}
