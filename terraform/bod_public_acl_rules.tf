# Allow ingress from the private subnet via https (for AWS CLI) and
# SMTP (for sending emails).  This allows EC2 instances in the private
# subnet to send the traffic they want via the NAT gateway, subject to
# their own security group and network ACL restrictions.
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

# Allow egress anywhere via HTTPS (for AWS CLI) and SMTP (for sending
# emails).  This is so the NAT gateway can relay the corresponding
# requests from the private subnet.
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
