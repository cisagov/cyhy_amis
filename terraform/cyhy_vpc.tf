# The CyHy VPC
resource "aws_vpc" "cyhy_vpc" {
  cidr_block = "10.10.10.0/23"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "CyHy"))}"
}

# Setup DHCP so we can resolve our private domain
resource "aws_vpc_dhcp_options" "cyhy_dhcp_options" {
  domain_name = "${local.private_domain}"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = "${merge(var.tags, map("Name", "CyHy"))}"
}

# Assoicate the DHCP options above with the CyHy VPC
resource "aws_vpc_dhcp_options_association" "cyhy_vpc_dhcp" {
  vpc_id          = "${aws_vpc.cyhy_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.cyhy_dhcp_options.id}"
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

# Route all BOD traffic through the VPC peering connection
resource "aws_route" "cyhy_route_external_traffic_through_vpc_peering_connection" {
  route_table_id = "${aws_default_route_table.cyhy_default_route_table.id}"
  destination_cidr_block = "${aws_vpc.bod_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_connection.id}"
}

# Route all external traffic through the NAT gateway
resource "aws_route" "cyhy_route_external_traffic_through_nat_gateway" {
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
resource "aws_route" "cyhy_route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.cyhy_scanner_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.cyhy_igw.id}"
}

# Associate the route table with the scanner subnet
resource "aws_route_table_association" "cyhy_association" {
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

# ACL for the scanner subnet of the VPC
resource "aws_network_acl" "cyhy_scanner_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_scanner_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

# Security group for the private portion of the VPC
resource "aws_security_group" "cyhy_private_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Security group for the scanner portion of the VPC
resource "aws_security_group" "cyhy_scanner_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Scanners"))}"
}

# Security group for the bastion host
resource "aws_security_group" "cyhy_bastion_sg" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Bastion"))}"
}
