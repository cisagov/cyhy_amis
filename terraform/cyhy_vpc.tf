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
# All traffic from portscanner, vulnscanner, and private subnets will
# route through here
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

# The Elastic IPs for the *Production* CyHy Port/Vuln Scanner NAT gateways
# Can be created via dhs-ncats/elastic-ips-terraform or manually
# Intended to be public IP addresses that rarely change
data "aws_eip" "cyhy_portscan_nat_gw_eip" {
  count = "${local.production_workspace ? 1 : 0}"
  public_ip = "${var.cyhy_portscan_nat_gw_elastic_ip}"
}

data "aws_eip" "cyhy_vulnscan_nat_gw_eip" {
  count = "${local.production_workspace ? 1 : 0}"
  public_ip = "${var.cyhy_vulnscan_nat_gw_elastic_ip}"
}

# The Elastic IPs for the *Non-Production* CyHy Port/Vuln Scanner NAT gateways
# Only created in *non-production* workspaces
# This are randomly-assigned public IP addresses for temporary use
resource "aws_eip" "cyhy_portscan_nat_gw_random_eip" {
  count = "${local.production_workspace ? 0 : 1}"
  vpc = true
  tags = "${merge(var.tags, map("Name", "CyHy Port Scanner NATGW EIP", "Publish Egress", "True"))}"
}

resource "aws_eip" "cyhy_vulnscan_nat_gw_random_eip" {
  count = "${local.production_workspace ? 0 : 1}"
  vpc = true
  tags = "${merge(var.tags, map("Name", "CyHy Vuln Scanner NATGW EIP", "Publish Egress", "True"))}"
}

# The Port Scanner NAT gateway for the VPC
# Resides in public subnet; used by portscanner and private subnets
resource "aws_nat_gateway" "cyhy_portscanner_nat_gw" {
  # Since our elastic IPs are handled differently in production vs.
  # non-production workspaces, their corresponding terraform resources
  # (data.aws_eip.cyhy_portscan_nat_gw_eip,
  #  data.aws_eip.cyhy_vulnscan_nat_gw_eip,
  #  aws_eip.cyhy_portscan_nat_gw_random_eip,
  #  aws_eip.cyhy_vulncan_nat_gw_random_eip)
  # may or may not be created.  To handle that, we use "splat syntax" (the *),
  # which resolves to either an empty list (if the resource is not present in
  # the current workspace) or a valid list (if the resource is present).  Then
  # we use coalescelist() to choose the (non-empty) list containing the valid
  # eip.id. Finally, we use element() to choose the first element in that
  # non-empty list, which is the allocation_id of our elastic IP.
  # See https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
  # VOTED WORST LINE OF TERRAFORM 2018 (so far) BY DEV TEAM WEEKLY!!
  allocation_id = "${element(coalescelist(data.aws_eip.cyhy_portscan_nat_gw_eip.*.id, aws_eip.cyhy_portscan_nat_gw_random_eip.*.id), 0)}"
  subnet_id = "${aws_subnet.cyhy_public_subnet.id}"

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Port Scanner NATGW"))}"
}

# The Vuln Scanner NAT gateway for the VPC
# Resides in public subnet; used by vulnscanner subnet
resource "aws_nat_gateway" "cyhy_vulnscanner_nat_gw" {
  # See comment above (aws_nat_gateway.cyhy_portscanner_nat_gw) explaining
  # the next trainwreck of a line
  allocation_id = "${element(coalescelist(data.aws_eip.cyhy_vulnscan_nat_gw_eip.*.id, aws_eip.cyhy_vulnscan_nat_gw_random_eip.*.id), 0)}"
  subnet_id = "${aws_subnet.cyhy_public_subnet.id}"

  depends_on = [
    "aws_internet_gateway.cyhy_igw"
  ]

  tags = "${merge(var.tags, map("Name", "CyHy Vuln Scanner NATGW"))}"
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "cyhy_igw" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy IGW"))}"
}

# Default route table for VPC, which routes all external traffic through the
# Port Scanner NAT gateway
resource "aws_default_route_table" "cyhy_default_route_table" {
  default_route_table_id = "${aws_vpc.cyhy_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "CyHy Port Scanners"))}"
}

# Default route: Route all external traffic through the Port Scanner NAT gateway
resource "aws_route" "cyhy_default_route_external_traffic_through_portscanner_nat_gateway" {
  route_table_id = "${aws_default_route_table.cyhy_default_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.cyhy_portscanner_nat_gw.id}"
}

# Route table for our vulnscanner subnet, which routes all external traffic
# through the Vuln Scanner NAT gateway
resource "aws_route_table" "cyhy_vulnscanner_route_table" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Vuln Scanners"))}"
}

# Vulnscanner route: Route all external traffic through the Vuln Scanner NAT gateway
resource "aws_route" "cyhy_vulnscanner_route_external_traffic_through_vulnscanner_nat_gateway" {
  route_table_id = "${aws_route_table.cyhy_vulnscanner_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.cyhy_vulnscanner_nat_gw.id}"
}

# Associate the route table with the vulnscanner subnet
resource "aws_route_table_association" "cyhy_vulnscanner_association" {
  subnet_id = "${aws_subnet.cyhy_vulnscanner_subnet.id}"
  route_table_id = "${aws_route_table.cyhy_vulnscanner_route_table.id}"
}

# Route table for our private subnet, which routes:
# - all BOD traffic through the VPC peering connection
# - all other external traffic through the Port Scanner NAT gateway
resource "aws_route_table" "cyhy_private_route_table" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Private"))}"
}

# Private route: Route all BOD traffic through the VPC peering connection
resource "aws_route" "cyhy_private_route_external_traffic_through_vpc_peering_connection" {
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
  destination_cidr_block = "${aws_vpc.bod_vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_connection.id}"
}

# Private route: Route all (non-BOD) external traffic through the
# Port Scanner NAT gateway
resource "aws_route" "cyhy_private_route_external_traffic_through_portscanner_nat_gateway" {
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.cyhy_portscanner_nat_gw.id}"
}

# Associate the route table with the private subnet
resource "aws_route_table_association" "cyhy_private_association" {
  subnet_id = "${aws_subnet.cyhy_private_subnet.id}"
  route_table_id = "${aws_route_table.cyhy_private_route_table.id}"
}

# Route table for our public subnet, which routes all external traffic
# through the internet gateway
resource "aws_route_table" "cyhy_public_route_table" {
  vpc_id = "${aws_vpc.cyhy_vpc.id}"

  tags = "${merge(var.tags, map("Name", "CyHy Public"))}"
}

# Public route: Route all external traffic through the internet gateway
resource "aws_route" "cyhy_public_route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.cyhy_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.cyhy_igw.id}"
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "cyhy_public_association" {
  subnet_id = "${aws_subnet.cyhy_public_subnet.id}"
  route_table_id = "${aws_route_table.cyhy_public_route_table.id}"
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
