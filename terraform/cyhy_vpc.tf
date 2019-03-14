# The CyHy VPC
resource "aws_vpc" "cyhy_vpc" {
  cidr_block = "10.10.10.0/23"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "CyHy"))}"
}

# Setup DHCP so we can resolve our private domain
resource "aws_vpc_dhcp_options" "cyhy_dhcp_options" {
  domain_name = "${local.cyhy_private_domain}"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = "${merge(var.tags, map("Name", "CyHy"))}"
}

# Associate the DHCP options above with the CyHy VPC
resource "aws_vpc_dhcp_options_association" "cyhy_vpc_dhcp" {
  vpc_id          = "${aws_vpc.cyhy_vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.cyhy_dhcp_options.id}"
}

# Private subnet of the VPC, for database and CyHy commander
resource "aws_subnet" "cyhy_private_subnet" {
 vpc_id = "${aws_vpc.cyhy_vpc.id}"
 cidr_block = "10.10.10.0/25"
 availability_zone = "${var.aws_region}${var.aws_availability_zone}"

 depends_on = [
   "aws_internet_gateway.cyhy_igw"
 ]

 tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Port scanner subnet of the VPC
resource "aws_subnet" "cyhy_portscanner_subnet" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  cidr_block = "10.10.11.0/25"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  tags = "${merge(var.tags, map("Name", "CyHy Port Scanners"))}"
}

# Vuln scanner subnet of the VPC
resource "aws_subnet" "cyhy_vulnscanner_subnet" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  cidr_block = "10.10.11.128/25"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  tags = "${merge(var.tags, map("Name", "CyHy Vuln Scanners"))}"
}

# Public subnet of the VPC
#
# All traffic from private subnet will route through here
resource "aws_subnet" "cyhy_public_subnet" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  # TODO: Maybe make this subnet smaller?
  cidr_block = "10.10.10.128/25"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Public"))}"
}

# Elastic IP for the NAT gateway
resource "aws_eip" "cyhy_eip" {
  vpc = true

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy NAT GW IP"))}"
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "cyhy_nat_gw" {
  allocation_id = "${aws_eip.cyhy_eip.id}"
  subnet_id = "${aws_subnet.cyhy_public_subnet.id}"

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy NAT GW"))}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "cyhy_igw" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy IGW"))}"
}

# Default route table for VPC, which routes all external traffic
# through the internet gateway
resource "aws_default_route_table" "cyhy_default_route_table" {
  default_route_table_id = "${aws_vpc.cyhy_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "CyHy Port Scanners"))}"
}

# Default route: Route all external traffic through the internet
# gateway
resource "aws_route" "cyhy_default_route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_default_route_table.cyhy_default_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.cyhy_igw.id}"
}

# Default route: Route all Management traffic through the VPC peering
# connection
resource "aws_route" "cyhy_default_route_mgmt_traffic_through_mgmt_vpc_peering_connection" {
  count = "${var.enable_mgmt_vpc}"

  route_table_id = "${aws_default_route_table.cyhy_default_route_table.id}"
  destination_cidr_block = "${aws_vpc.mgmt_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.cyhy_mgmt_peering_connection.id}"
}

# Route table for our private subnet, which routes:
# - all BOD traffic through the VPC peering connection
# - all management VPC traffic through the VPC peering connection
# - all other external traffic through the NAT gateway
resource "aws_route_table" "cyhy_private_route_table" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Private route: Route all BOD traffic through the VPC peering
# connection
resource "aws_route" "cyhy_private_route_external_traffic_through_bod_vpc_peering_connection" {
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
  destination_cidr_block = "${aws_vpc.bod_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.cyhy_bod_peering_connection.id}"
}

# Private route: Route all Management traffic through the VPC peering
# connection
resource "aws_route" "cyhy_private_route_external_traffic_through_mgmt_vpc_peering_connection" {
  count = "${var.enable_mgmt_vpc}"
  
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
  destination_cidr_block = "${aws_vpc.mgmt_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.cyhy_mgmt_peering_connection.id}"
}

# Private route: Route all (non-BOD) external traffic through the NAT
# gateway
resource "aws_route" "cyhy_private_route_external_traffic_through_nat_gateway" {
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.cyhy_nat_gw.id}"
}

# Associate the route table with the private subnet
resource "aws_route_table_association" "cyhy_private_association" {
  subnet_id = "${aws_subnet.cyhy_private_subnet.id}"
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
}

# ACL for the private subnet of the VPC
resource "aws_network_acl" "cyhy_private_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_private_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# ACL for the portscanner subnet of the VPC
resource "aws_network_acl" "cyhy_portscanner_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_portscanner_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Port Scanners"))}"
}

# ACL for the vulnscanner subnet of the VPC
resource "aws_network_acl" "cyhy_vulnscanner_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_vulnscanner_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Vuln Scanners"))}"
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "cyhy_public_acl" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
  subnet_ids = [
    "${aws_subnet.cyhy_public_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Public"))}"
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
