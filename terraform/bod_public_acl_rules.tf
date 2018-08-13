# Allow ingress from the private subnet via HTTP (for downloading the
# public suffix list), HTTPS (for AWS CLI), SMTP (for sending emails),
# and DNS (for Google DNS).  This allows EC2 instances in the private
# subnet to send the traffic they want via the NAT gateway, subject to
# their own security group and network ACL restrictions.
resource "aws_network_acl_rule" "public_ingress_from_private_via_http" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 79
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_https" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 80
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 443
  to_port = 443
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 81
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 587
  to_port = 587
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_53_tcp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "tcp"
  rule_number = 82
  rule_action = "allow"
  cidr_block = "${aws_subnet.bod_private_subnet.cidr_block}"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_ingress_from_private_via_port_53_udp" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = false
  protocol = "udp"
  rule_number = 83
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
#
# TODO - This should be locked down using
# var/trusted_ingress_networks_ipv4 and
# var/trusted_ingress_networks_ipv6
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
resource "aws_network_acl_rule" "public_egress_anywhere_via_http" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 129
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_https" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 130
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}
resource "aws_network_acl_rule" "public_egress_anywhere_via_port_587" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 131
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 587
  to_port = 587
}

# Allow egress to Google DNS.  This is so the NAT gateway can relay
# the corresponding requests from the private subnet.
resource "aws_network_acl_rule" "public_egress_to_google_dns_tcp_1" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 135
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_egress_to_google_dns_tcp_2" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "tcp"
  rule_number = 136
  rule_action = "allow"
  cidr_block = "8.8.4.4/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_egress_to_google_dns_udp_1" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 137
  rule_action = "allow"
  cidr_block = "8.8.8.8/32"
  from_port = 53
  to_port = 53
}
resource "aws_network_acl_rule" "public_egress_to_google_dns_udp_2" {
  network_acl_id = "${aws_network_acl.bod_public_acl.id}"
  egress = true
  protocol = "udp"
  rule_number = 138
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
