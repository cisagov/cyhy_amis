# The Management VPC
resource "aws_vpc" "mgmt_vpc" {
  cidr_block = "10.10.14.0/23"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "Management"))}"
}

# Setup DHCP so we can resolve our private domain
resource "aws_vpc_dhcp_options" "mgmt_dhcp_options" {
  domain_name = "${local.mgmt_private_domain}"
  domain_name_servers = [
    "AmazonProvidedDNS"
  ]
  tags = "${merge(var.tags, map("Name", "Management"))}"
}

# Associate the DHCP options above with the VPC
resource "aws_vpc_dhcp_options_association" "mgmt_vpc_dhcp" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.mgmt_dhcp_options.id}"
}

# Private subnet of the VPC
resource "aws_subnet" "mgmt_private_subnet" {
 vpc_id = "${aws_vpc.mgmt_vpc.id}"
 cidr_block = "10.10.14.0/24"
 availability_zone = "${var.aws_region}${var.aws_availability_zone}"

 depends_on = [
   "aws_internet_gateway.mgmt_igw"
 ]

 tags = "${merge(var.tags, map("Name", "Management Private"))}"
}

# Public subnet of the VPC
resource "aws_subnet" "mgmt_public_subnet" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"
  cidr_block = "10.10.15.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [
    "aws_internet_gateway.mgmt_igw"
  ]

  tags = "${merge(var.tags, map("Name", "Management Public"))}"
}

# Elastic IP for the NAT gateway
resource "aws_eip" "mgmt_eip" {
  vpc = true

  depends_on = [
    "aws_internet_gateway.mgmt_igw"
  ]

  tags = "${merge(var.tags, map("Name", "Management NATGW IP"))}"
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "mgmt_nat_gw" {
  allocation_id = "${aws_eip.mgmt_eip.id}"
  subnet_id = "${aws_subnet.mgmt_public_subnet.id}"

  depends_on = [
    "aws_internet_gateway.mgmt_igw"
  ]

  tags = "${merge(var.tags, map("Name", "Management NATGW"))}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "mgmt_igw" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"

  tags = "${merge(var.tags, map("Name", "Management IGW"))}"
}

# Default route table
resource "aws_default_route_table" "mgmt_default_route_table" {
  default_route_table_id = "${aws_vpc.mgmt_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "Management default route table"))}"
}

# Route all CyHy traffic through the CyHy-Management VPC peering connection
resource "aws_route" "mgmt_route_cyhy_traffic_through_peering_connection" {
  route_table_id = "${aws_default_route_table.mgmt_default_route_table.id}"
  destination_cidr_block = "${aws_vpc.cyhy_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.cyhy_mgmt_peering_connection.id}"
}

# Route all BOD traffic through the BOD-Management VPC peering connection
resource "aws_route" "mgmt_route_bod_traffic_through_peering_connection" {
  route_table_id = "${aws_default_route_table.mgmt_default_route_table.id}"
  destination_cidr_block = "${aws_vpc.bod_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.bod_mgmt_peering_connection.id}"
}

# Route all external traffic through the NAT gateway
resource "aws_route" "mgmt_route_external_traffic_through_nat_gateway" {
  route_table_id = "${aws_default_route_table.mgmt_default_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.mgmt_nat_gw.id}"
}

# Route table for our public subnet
resource "aws_route_table" "mgmt_public_route_table" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"

  tags = "${merge(var.tags, map("Name", "Management public route table"))}"
}

# Route all external traffic through the internet gateway
resource "aws_route" "mgmt_public_route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.mgmt_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.mgmt_igw.id}"
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "mgmt_association" {
  subnet_id = "${aws_subnet.mgmt_public_subnet.id}"
  route_table_id = "${aws_route_table.mgmt_public_route_table.id}"
}

# ACL for the private subnet of the VPC
resource "aws_network_acl" "mgmt_private_acl" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"
  subnet_ids = [
    "${aws_subnet.mgmt_private_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "Management Private"))}"
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "mgmt_public_acl" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"
  subnet_ids = [
    "${aws_subnet.mgmt_public_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "Management Public"))}"
}

# Security group for the private portion of the VPC
resource "aws_security_group" "mgmt_private_sg" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"

  tags = "${merge(var.tags, map("Name", "Management Private"))}"
}

# Security group for the public portion of the VPC
resource "aws_security_group" "mgmt_public_sg" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"

  tags = "${merge(var.tags, map("Name", "Management Public"))}"
}

# Security group for the bastion host
resource "aws_security_group" "mgmt_bastion_sg" {
  vpc_id = "${aws_vpc.mgmt_vpc.id}"

  tags = "${merge(var.tags, map("Name", "Management Bastion"))}"
}
