# Allow ingress from trusted networks via the Nessus UI port
resource "aws_security_group_rule" "scanner_ingress_from_trusted_via_nessus" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = "${var.trusted_ingress_networks_ipv4}"
  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = 8834
  to_port = 8834
}

# Allow ingress from trusted networks via ssh
resource "aws_security_group_rule" "scanner_ingress_from_trusted_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = "${var.trusted_ingress_networks_ipv4}"
  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = 22
  to_port = 22
}

# Allow ingress from bastion via ssh.  This is necessary because
# Ansible applies the ssh proxy even when sshing to the bastion.
resource "aws_security_group_rule" "scanner_ingress_from_self_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_bastion.public_ip}/32"
  ]
  from_port = 22
  to_port = 22
}

# Allow ingress from anywhere via ephemeral ports
resource "aws_security_group_rule" "scanner_ingress_anywhere_tcp" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}
resource "aws_security_group_rule" "scanner_ingress_anywhere_udp" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "udp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 1024
  to_port = 65535
}

# Allow ingress via ssh from the private security group
resource "aws_security_group_rule" "scanner_ingress_from_private_sg_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow egress anywhere via all ports and protocols, since we're
# scanning
resource "aws_security_group_rule" "scanner_egress_anywhere" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "egress"
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 0
  to_port = 0
}

# Allow egress via ssh to the private security group
resource "aws_security_group_rule" "scanner_egress_to_private_sg_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  from_port = 22
  to_port = 22
}
