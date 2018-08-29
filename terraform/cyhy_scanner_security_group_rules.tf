# Allow ingress from the bastion security group via the ssh and Nessus
# ports
resource "aws_security_group_rule" "scanner_ingress_from_bastion_sg" {
  count = "${length(local.cyhy_trusted_ingress_ports)}"

  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_bastion_sg.id}"
  from_port = "${local.cyhy_trusted_ingress_ports[count.index]}"
  to_port = "${local.cyhy_trusted_ingress_ports[count.index]}"
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

# Allow ingress from anywhere via all other tcp ports
resource "aws_security_group_rule" "scanner_ingress_anywhere_tcp" {
  count = "${length(local.cyhy_untrusted_ingress_port_ranges)}"

  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = "${lookup(local.cyhy_untrusted_ingress_port_ranges[count.index], "start")}"
  to_port = "${lookup(local.cyhy_untrusted_ingress_port_ranges[count.index], "end")}"
}

# Allow ingress from anywhere via all udp ports
resource "aws_security_group_rule" "scanner_ingress_anywhere_udp" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "udp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = 0
  to_port = 0
}

# Allow ingress from anywhere via all icmp ports
resource "aws_security_group_rule" "scanner_ingress_anywhere_icmp" {
  security_group_id = "${aws_security_group.cyhy_scanner_sg.id}"
  type = "ingress"
  protocol = "icmp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = -1
  to_port = -1
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
