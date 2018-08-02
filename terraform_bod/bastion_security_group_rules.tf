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
