# The BOD 18-01 VPC
resource "aws_vpc" "bod_vpc" {
  cidr_block           = "10.11.0.0/21"
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01"
    },
  )
}

# Setup DHCP so we can resolve our private domain
resource "aws_vpc_dhcp_options" "bod_dhcp_options" {
  domain_name = local.bod_private_domain
  domain_name_servers = [
    "AmazonProvidedDNS",
  ]
  tags = merge(
    var.tags,
    {
      "Name" = "BOD"
    },
  )
}

# Associate the DHCP options above with the VPC
resource "aws_vpc_dhcp_options_association" "bod_vpc_dhcp" {
  vpc_id          = aws_vpc.bod_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.bod_dhcp_options.id
}

# Docker subnet of the VPC
resource "aws_subnet" "bod_docker_subnet" {
  vpc_id            = aws_vpc.bod_vpc.id
  cidr_block        = "10.11.1.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [aws_internet_gateway.bod_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Docker"
    },
  )
}

# Lambda subnet of the VPC
resource "aws_subnet" "bod_lambda_subnet" {
  vpc_id            = aws_vpc.bod_vpc.id
  cidr_block        = "10.11.4.0/22"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [aws_internet_gateway.bod_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Lambda"
    },
  )
}

# Public subnet of the VPC
resource "aws_subnet" "bod_public_subnet" {
  vpc_id            = aws_vpc.bod_vpc.id
  cidr_block        = "10.11.0.0/24"
  availability_zone = "${var.aws_region}${var.aws_availability_zone}"

  depends_on = [aws_internet_gateway.bod_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Public"
    },
  )
}

# The Elastic IP for the *production* NAT gateway
data "aws_eip" "bod_production_eip" {
  count     = local.production_workspace ? 1 : 0
  public_ip = var.bod_nat_gateway_eip
}

# The Elastic IP for the *non-production* NAT gateway
resource "aws_eip" "bod_nonproduction_eip" {
  count = local.production_workspace ? 0 : 1
  vpc   = true

  depends_on = [aws_internet_gateway.bod_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 NATGW IP"
    },
  )
}

# The NAT gateway for the VPC
resource "aws_nat_gateway" "bod_nat_gw" {
  # This affront to the laws of nature merits an explanation.
  #
  # Since our EIPs are handled differently in the production and
  # non-production workspaces, their corresponding Terraform resources
  # (data.aws_eip.bod_production_eip and
  # data.aws_eip.bod_nonpriduction_eip) may or may not be created.  To
  # handle that, we use splat syntax (the *), which resolves to either
  # an empty list (if the resource is not present in the current
  # workspace) or a valid list (if the resource is present).  Then we
  # use coalescelist() to choose the (single-valued) list containing
  # the valid eip.id. Finally, we use element() to choose the zeroth
  # element of that non-empty list, which is the allocation_id of our
  # elastic IP.  See
  # https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
  # for more details.
  allocation_id = element(
    coalescelist(
      data.aws_eip.bod_production_eip[*].id,
      aws_eip.bod_nonproduction_eip[*].id,
    ),
    0,
  )
  subnet_id = aws_subnet.bod_public_subnet.id

  depends_on = [aws_internet_gateway.bod_igw]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 NATGW"
    },
  )
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "bod_igw" {
  vpc_id = aws_vpc.bod_vpc.id

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 IGW"
    },
  )
}

# Default route table
resource "aws_default_route_table" "bod_default_route_table" {
  default_route_table_id = aws_vpc.bod_vpc.default_route_table_id

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 default route table"
    },
  )
}

# Route all CyHy traffic through the VPC peering connection
resource "aws_route" "bod_route_cyhy_traffic_through_peering_connection" {
  route_table_id            = aws_default_route_table.bod_default_route_table.id
  destination_cidr_block    = aws_vpc.cyhy_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.cyhy_bod_peering_connection.id
}

# Route all Management VPC traffic through the VPC peering connection
resource "aws_route" "bod_route_mgmt_traffic_through_peering_connection" {
  count = var.enable_mgmt_vpc ? 1 : 0

  route_table_id            = aws_default_route_table.bod_default_route_table.id
  destination_cidr_block    = aws_vpc.mgmt_vpc[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bod_mgmt_peering_connection[0].id
}

# Route all external traffic through the NAT gateway
resource "aws_route" "bod_route_external_traffic_through_nat_gateway" {
  route_table_id         = aws_default_route_table.bod_default_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.bod_nat_gw.id
}

# Route table for our public subnet
resource "aws_route_table" "bod_public_route_table" {
  vpc_id = aws_vpc.bod_vpc.id

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 public route table"
    },
  )
}

# Route all Management VPC traffic through the VPC peering connection
resource "aws_route" "bod_public_route_mgmt_traffic_through_peering_connection" {
  count = var.enable_mgmt_vpc ? 1 : 0

  route_table_id            = aws_route_table.bod_public_route_table.id
  destination_cidr_block    = aws_vpc.mgmt_vpc[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.bod_mgmt_peering_connection[0].id
}

# Route all external traffic through the internet gateway
resource "aws_route" "bod_public_route_external_traffic_through_internet_gateway" {
  route_table_id         = aws_route_table.bod_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bod_igw.id
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "bod_association" {
  subnet_id      = aws_subnet.bod_public_subnet.id
  route_table_id = aws_route_table.bod_public_route_table.id
}

# ACL for the docker subnet of the VPC
resource "aws_network_acl" "bod_docker_acl" {
  vpc_id = aws_vpc.bod_vpc.id
  subnet_ids = [
    aws_subnet.bod_docker_subnet.id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Docker"
    },
  )
}

# ACL for the Lambda subnet of the VPC
resource "aws_network_acl" "bod_lambda_acl" {
  vpc_id = aws_vpc.bod_vpc.id
  subnet_ids = [
    aws_subnet.bod_lambda_subnet.id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Lambda"
    },
  )
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "bod_public_acl" {
  vpc_id = aws_vpc.bod_vpc.id
  subnet_ids = [
    aws_subnet.bod_public_subnet.id,
  ]

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Public"
    },
  )
}

# Security group for the Docker portion of the VPC
resource "aws_security_group" "bod_docker_sg" {
  vpc_id = aws_vpc.bod_vpc.id

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Docker"
    },
  )
}

# Security group for the Lambda portion of the VPC
resource "aws_security_group" "bod_lambda_sg" {
  vpc_id = aws_vpc.bod_vpc.id

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Lambda"
    },
  )
}

# Security group for the bastion portion of the VPC
resource "aws_security_group" "bod_bastion_sg" {
  vpc_id = aws_vpc.bod_vpc.id

  tags = merge(
    var.tags,
    {
      "Name" = "BOD 18-01 Bastion"
    },
  )
}
