# Allow SSH ingress from the bastion security group
resource "aws_security_group_rule" "docker_ssh_ingress_from_bastion" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow HTTP, HTTPS, SMTP (587), and FTP egress anywhere
resource "aws_security_group_rule" "docker_anywhere" {
  count = "${length(local.bod_docker_egress_anywhere_ports)}"

  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
  to_port = "${local.bod_docker_egress_anywhere_ports[count.index]}"
}

# Allow DNS egress to Google
resource "aws_security_group_rule" "docker_dns_to_google" {
  count = "${length(local.tcp_and_udp)}"

  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "${local.tcp_and_udp[count.index]}"
  cidr_blocks = [
    "8.8.8.8/32",
    "8.8.4.4/32"
  ]
  from_port = 53
  to_port = 53
}

# Allow egress via the MongoDB port to the "CyHy Private" security
# group
resource "aws_security_group_rule" "docker_egress_to_cyhy_private_via_mongodb" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "egress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.cyhy_private_sg.id}"
  from_port = 27017
  to_port = 27017
}
