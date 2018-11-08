# The BOD 18-01 VPC
resource "aws_vpc" "bod_vpc" {
  cidr_block = "10.10.12.0/23"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "BOD 18-01"))}"
}

# Setup DHCP so we can resolve our private domain
resource "aws_vpc_dhcp_options" "bod_dhcp_options" {
  domain_name = "${local.bod_private_domain}"
  domain_name_servers = [
    "AmazonProvidedDNS"
  ]
  tags = "${merge(var.tags, map("Name", "BOD"))}"
}

# Associate the DHCP options above with the VPC
resource "aws_vpc_dhcp_options_association" "bod_vpc_dhcp" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.bod_dhcp_options.id}"
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

# Default route table
resource "aws_default_route_table" "bod_default_route_table" {
  default_route_table_id = "${aws_vpc.bod_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 default route table"))}"
}

# Route all CyHy traffic through the VPC peering connection
resource "aws_route" "bod_route_cyhy_traffic_through_peering_connection" {
  route_table_id = "${aws_default_route_table.bod_default_route_table.id}"
  destination_cidr_block = "${aws_vpc.cyhy_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.cyhy_bod_peering_connection.id}"
}

# Route all external traffic through the NAT gateway
resource "aws_route" "bod_route_external_traffic_through_nat_gateway" {
  route_table_id = "${aws_default_route_table.bod_default_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.bod_nat_gw.id}"
}

# Route table for our public subnet
resource "aws_route_table" "bod_public_route_table" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 public route table"))}"
}

# Route all external traffic through the internet gateway
resource "aws_route" "bod_public_route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.bod_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.bod_igw.id}"
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "bod_association" {
  subnet_id = "${aws_subnet.bod_public_subnet.id}"
  route_table_id = "${aws_route_table.bod_public_route_table.id}"
}

# ACL for the private subnet of the VPC
resource "aws_network_acl" "bod_private_acl" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  subnet_ids = [
    "${aws_subnet.bod_private_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Private"))}"
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "bod_public_acl" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  subnet_ids = [
    "${aws_subnet.bod_public_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Public"))}"
}

# Security group for the Docker portion of the VPC
resource "aws_security_group" "bod_docker_sg" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  
  tags = "${merge(var.tags, map("Name", "BOD 18-01 Docker"))}"
}

# Security group for the public portion of the VPC
resource "aws_security_group" "bod_public_sg" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Public"))}"
}

# Security group for the bastion portion of the VPC
resource "aws_security_group" "bod_bastion_sg" {
  vpc_id = "${aws_vpc.bod_vpc.id}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Bastion"))}"
}
