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

# Default route table
resource "aws_default_route_table" "bod_default_route_table" {
  default_route_table_id = "${aws_vpc.bod_vpc.default_route_table_id}"

  tags = "${merge(var.tags, map("Name", "BOD 18-01 default route table"))}"
}

# Route all external traffic through the NAT gateway
resource "aws_route" "route_external_traffic_through_nat_gateway" {
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
resource "aws_route" "route_external_traffic_through_internet_gateway" {
  route_table_id = "${aws_route_table.bod_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.bod_igw.id}"
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

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Private"))}"
}

# Allow ssh ingress from the public subnet
resource "aws_network_acl_rule" "private_ingress_from_public_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

# Allow ingress via ephemeral ports from anywhere
resource "aws_network_acl_rule" "private_ingress_anywhere_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 110
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow outbound HTTP and HTTPS
resource "aws_network_acl_rule" "private_egress_anywhere_via_http" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 131
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# Allow outbound SMTP
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_25" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 25
  to_port = 25
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_465" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 141
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 465
  to_port = 465
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 142
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 587
  to_port = 587
}

# Allow egress anywhere via DNS.  This is so the NAT gateway can relay
# the corresponding requests from the private subnet.
resource "aws_network_acl_rule" "private_egress_anywhere_via_dns_tcp" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "private_egress_anywhere_via_dns_udp" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 151
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}

# Allow egress to the public subnet via ephemeral ports
resource "aws_network_acl_rule" "private_egress_to_public_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_private_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 160
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_public_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}

# ACL for the public subnet of the VPC
resource "aws_network_acl" "bod_public_acl" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  subnet_ids = [
    "${aws_subnet.bod_public_subnet.id}"
  ]

  tags = "${merge(var.tags, map("Name", "BOD 18-01 Public"))}"
}

# Allow ingress from the private subnet via any port and protocol.
# This allows EC2 instances in the private subnet to send any traffic
# they want via the NAT gateway, subject to their own security group
# and network ACL restrictions.
resource "aws_network_acl_rule" "public_ingress_from_private_via_all_ports_and_protocols" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "-1"
  rule_number = 80
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 0
  to_port = 0
}

# Allow ingress from anywhere via ephemeral ports.  This is necessary
# because the return traffic to the NAT gateway has to enter here
# before it is relayed to the private subnet.
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 90
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow ingress from anywhere via ssh
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 100
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}

# Allow egress to the private subnet via ssh
resource "aws_network_acl_rule" "public_egress_to_private_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress anywhere via http and https.  This is so the NAT
# gateway can relay the corresponding requests from the private
# subnet.
resource "aws_network_acl_rule" "public_egress_anywhere_via_http" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 141
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# Allow egress anywhere via SMTP.  This is so the NAT gateway can
# relay the corresponding requests from the private subnet.
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_25" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 25
  to_port = 25
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_465" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 151
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 465
  to_port = 465
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 152
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 587
  to_port = 587
}

# Allow egress anywhere via DNS.  This is so the NAT gateway can relay
# the corresponding requests from the private subnet.
resource "aws_network_acl_rule" "public_egress_anywhere_via_dns_tcp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 160
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_dns_udp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 161
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 53
  to_port = 53
}

# Allow egress to anywhere via ephemeral ports
resource "aws_network_acl_rule" "public_egress_to_anywhere_via_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 170
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Security group for the Docker portion of the VPC
resource "aws_security_group" "bod_docker_sg" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  
  tags = "${merge(var.tags, map("Name", "BOD 18-01 Docker"))}"
}

# Allow SSH ingress from the bastion security group
resource "aws_security_group_rule" "docker_ssh_ingress_from_bastion" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow HTTP and HTTPS egress anywhere
resource "aws_security_group_rule" "docker_http_anywhere" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 80
  to_port = 80
}
resource "aws_security_group_rule" "docker_https_anywhere" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 443
  to_port = 443
}

# Allow SMTP egress anywhere
resource "aws_security_group_rule" "docker_port_25_anywhere" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 25
  to_port = 25
}
resource "aws_security_group_rule" "docker_port_465_anywhere" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 465
  to_port = 465
}
resource "aws_security_group_rule" "docker_port_587_anywhere" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 587
  to_port = 587
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

# Allow ssh ingress from anywhere
resource "aws_security_group_rule" "bastion_ssh_from_anywhere" {
  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 22
  to_port = 22
}

# Allow ssh egress to the docker security group
resource "aws_security_group_rule" "bastion_ssh_to_docker" {
  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.bod_docker_sg.id}"
  from_port = 22
  to_port = 22
}
