# Allow ingress from trusted networks via the Nessus UI and ssh ports
resource "aws_security_group_rule" "scanner_ingress_from_trusted" {
  count = "${length(local.cyhy_trusted_ingress_ports)}"

  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = "${var.trusted_ingress_networks_ipv4}"
  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = "${local.cyhy_trusted_ingress_ports[count.index]}"
  to_port = "${local.cyhy_trusted_ingress_ports[count.index]}"
}

# Allow ingress from the bastion via ssh
resource "aws_security_group_rule" "scanner_ingress_from_bastion_via_ssh" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_bastion.public_ip}/32"
  ]
  from_port = 22
  to_port = 22
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
