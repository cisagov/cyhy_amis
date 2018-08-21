# Allow ssh ingress from trusted ingress networks
resource "aws_security_group_rule" "bastion_ssh_from_trusted" {
  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = "${var.trusted_ingress_networks_ipv4}"
  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = 22
  to_port = 22
}

# Allow ingress from and egress to the bastion via ssh.  This is
# necessary because Ansible applies the ssh proxy even when sshing to
# the bastion.
resource "aws_security_group_rule" "bastion_self_ssh" {
  count = "${length(local.ingress_and_egress)}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "${local.ingress_and_egress[count.index]}"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.bod_bastion.public_ip}/32"
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
