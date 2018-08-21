# Allow ingress from the private subnet via HTTP (for downloading the
# public suffix list), HTTPS (for AWS CLI), SMTP (for sending emails),
# and DNS (for Google DNS).  This allows EC2 instances in the private
# subnet to send the traffic they want via the NAT gateway, subject to
# their own security group and network ACL restrictions.
resource "aws_network_acl_rule" "public_ingress_from_private" {
  count = "${length(local.bod_docker_egress_anywhere_ports)}"

  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = "${80 + count.index}"
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
  to_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_53" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${85 + count.index}"
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 53
  to_port = 53
}

# Allow ingress from anywhere via ephemeral ports for TCP.  This is
# necessary because the return traffic to the NAT gateway has to enter
# here before it is relayed to the private subnet.
resource "aws_network_acl_rule" "public_ingress_from_anywhere_via_ephemeral_ports_tcp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 90
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow ingress from Google DNS via ephemeral ports for UDP.  This is
# necessary because the return traffic to the NAT gateway has to enter
# here before it is relayed to the private subnet.
resource "aws_network_acl_rule" "public_ingress_from_google_dns_via_ephemeral_ports_udp_1" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 95
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 1024
  to_port = 65535
}
resource "aws_network_acl_rule" "public_ingress_from_google_dns_via_ephemeral_ports_udp_2" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 96
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
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
  rule_number = 110
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 22
  to_port = 22
}

# Allow egress to the bastion via ssh.  This is necessary because
# Ansible applies the ssh proxy even when sshing to the bastion.
resource "aws_network_acl_rule" "public_egress_to_bastion_via_ssh" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 120
  rule_action = "allow"
  cidr_block = "${aws_instance.bod_bastion.public_ip}/32"
  from_port = 22
  to_port = 22
}

# Allow egress anywhere via HTTP (for downloading the public suffix
# list), HTTPS (for AWS CLI) and SMTP (for sending emails).  This is
# so the NAT gateway can relay the corresponding requests from the
# private subnet.
resource "aws_network_acl_rule" "public_egress_anywhere" {
  count = "${length(local.bod_docker_egress_anywhere_ports)}"

  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = "${129 + count.index}"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
  to_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
}

# Allow egress to Google DNS.  This is so the NAT gateway can relay
# the corresponding requests from the private subnet.
resource "aws_network_acl_rule" "public_egress_to_google_dns_1" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${135 + count.index}"
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_egress_to_google_dns_2" {
  count = "${length(local.tcp_and_udp)}"

  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "${local.tcp_and_udp[count.index]}"
  rule_number = "${137 + count.index}"
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 53
  to_port = 53
}

# Allow egress to anywhere via TCP ephemeral ports
resource "aws_network_acl_rule" "public_egress_to_anywhere_via_tcp_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 140
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Allow egress to the private subnet via UDP ephemeral ports
resource "aws_network_acl_rule" "public_egress_to_private_via_udp_ephemeral_ports" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 150
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 1024
  to_port = 65535
}
