# Allow SSH ingress from the bastion security group
resource "aws_security_group_rule" "docker_ssh_ingress_from_bastion" {
  security_group_id = "${aws_security_group.bod_docker_sg.id}"
  type = "ingress"
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  from_port = 22
  to_port = 22
}

# Allow HTTPS egress anywhere
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
