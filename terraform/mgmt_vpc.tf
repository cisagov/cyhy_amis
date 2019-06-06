# The Management VPC
resource "aws_vpc" "mgmt_vpc" {
  count = var.enable_mgmt_vpc

  cidr_block           = "10.10.14.0/23"
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name" = "Management"
    },
  )
}

# Setup DHCP so we can resolve our private domain
resource "aws_vpc_dhcp_options" "mgmt_dhcp_options" {
  count = var.enable_mgmt_vpc

  domain_name = local.mgmt_private_domain
  domain_name_servers = [
    "AmazonProvidedDNS",
  ]
  tags = merge(
    var.tags,
    {
      "Name" = "Management"
    },
  )
}

# Associate the DHCP options above with the VPC
resource "aws_vpc_dhcp_options_association" "mgmt_vpc_dhcp" {
  count = var.enable_mgmt_vpc

  vpc_id          = aws_vpc.mgmt_vpc[0].id
  dhcp_options_id = aws_vpc_dhcp_options.mgmt_dhcp_options[0].id
}

# Private subnet of the VPC
resource "aws_subnet" "mgmt_private_subnet" {
  count = var.enable_mgmt_vpc

  vpc_id            = aws_vpc.mgmt_vpc[0].id
  cidr_block        = "10.10.14.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [aws_internet_gateway.mgmt_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "Management Private"
    },
  )
}

# Public subnet of the VPC
resource "aws_subnet" "mgmt_public_subnet" {
  count = var.enable_mgmt_vpc

  vpc_id            = aws_vpc.mgmt_vpc[0].id
  cidr_block        = "10.10.15.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [aws_internet_gateway.mgmt_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "Management Public"
    },
  )
}

# Elastic IP for the NAT gateway
resource "aws_eip" "mgmt_eip" {
  count = var.enable_mgmt_vpc

  vpc = true

  depends_on = [aws_internet_gateway.mgmt_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "Management NATGW IP"
    },
  )
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "mgmt_nat_gw" {
  count = var.enable_mgmt_vpc

  allocation_id = aws_eip.mgmt_eip[0].id
  subnet_id     = aws_subnet.mgmt_public_subnet[0].id

  depends_on = [aws_internet_gateway.mgmt_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "Management NATGW"
    },
  )
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "mgmt_igw" {
  count = var.enable_mgmt_vpc

  vpc_id = aws_vpc.mgmt_vpc[0].id

  tags = merge(
    var.tags,
    {
      "Name" = "Management IGW"
    },
  )
}

# Default route table
resource "aws_default_route_table" "mgmt_default_route_table" {
  count = var.enable_mgmt_vpc

  default_route_table_id = aws_vpc.mgmt_vpc[0].default_route_table_id

  tags = merge(
    var.tags,
    {
      "Name" = "Management default route table"
    },
  )
}

# Route all CyHy traffic through the CyHy-Management VPC peering connection
resource "aws_route" "mgmt_route_cyhy_traffic_through_peering_connection" {
  count = var.enable_mgmt_vpc

  route_table_id            = aws_default_route_table.mgmt_default_route_table[0].id
  destination_cidr_block    = aws_vpc.cyhy_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cyhy_mgmt_peering_connection[0].id
}

# Route all BOD traffic through the BOD-Management VPC peering connection
resource "aws_route" "mgmt_route_bod_traffic_through_peering_connection" {
  count = var.enable_mgmt_vpc

  route_table_id            = aws_default_route_table.mgmt_default_route_table[0].id
  destination_cidr_block    = aws_vpc.bod_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bod_mgmt_peering_connection[0].id
}

# Route all external traffic through the NAT gateway
resource "aws_route" "mgmt_route_external_traffic_through_nat_gateway" {
  count = var.enable_mgmt_vpc

  route_table_id         = aws_default_route_table.mgmt_default_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.mgmt_nat_gw[0].id
}

# Route table for our public subnet
resource "aws_route_table" "mgmt_public_route_table" {
  count = var.enable_mgmt_vpc

  vpc_id = aws_vpc.mgmt_vpc[0].id

  tags = merge(
    var.tags,
    {
      "Name" = "Management public route table"
    },
  )
}

# Route all external traffic through the internet gateway
resource "aws_route" "mgmt_public_route_external_traffic_through_internet_gateway" {
  count = var.enable_mgmt_vpc

  route_table_id         = aws_route_table.mgmt_public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mgmt_igw[0].id
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "mgmt_association" {
  count = var.enable_mgmt_vpc

  subnet_id      = aws_subnet.mgmt_public_subnet[0].id
  route_table_id = aws_route_table.mgmt_public_route_table[0].id
}

# ACL for the private subnet of the VPC
resource "aws_network_acl" "mgmt_private_acl" {
  count = var.enable_mgmt_vpc

  vpc_id = aws_vpc.mgmt_vpc[0].id
  subnet_ids = [
    aws_subnet.mgmt_private_subnet[0].id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "Management Private"
    },
  )
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "mgmt_public_acl" {
  count = var.enable_mgmt_vpc

  vpc_id = aws_vpc.mgmt_vpc[0].id
  subnet_ids = [
    aws_subnet.mgmt_public_subnet[0].id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "Management Public"
    },
  )
}

# Security group for scanner hosts (private subnet)
resource "aws_security_group" "mgmt_scanner_sg" {
  count = var.enable_mgmt_vpc

  vpc_id = aws_vpc.mgmt_vpc[0].id

  tags = merge(
    var.tags,
    {
      "Name" = "Management Scanner"
    },
  )
}

# Security group for the bastion host (public subnet)
resource "aws_security_group" "mgmt_bastion_sg" {
  count = var.enable_mgmt_vpc

  vpc_id = aws_vpc.mgmt_vpc[0].id

  tags = merge(
    var.tags,
    {
      "Name" = "Management Bastion"
    },
  )
}

