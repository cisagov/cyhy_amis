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

# Allow all ICMP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "bod_bastion_ingress_all_icmp_from_mgmt_vulnscan" {
  count = "${var.enable_mgmt_vpc_access_to_all_vpcs}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "ingress"
  protocol = "icmp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus.private_ip}/32"
  ]
  from_port = -1
  to_port = -1
}

# Allow all TCP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "bod_bastion_ingress_all_tcp_from_mgmt_vulnscan" {
  count = "${var.enable_mgmt_vpc_access_to_all_vpcs}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "ingress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus.private_ip}/32"
  ]
  from_port = 0
  to_port = 0
}

# Allow all UDP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "bod_bastion_ingress_all_udp_from_mgmt_vulnscan" {
  count = "${var.enable_mgmt_vpc_access_to_all_vpcs}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "ingress"
  protocol = "udp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus.private_ip}/32"
  ]
  from_port = 0
  to_port = 0
}

# Allow all ICMP to vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "bod_bastion_egress_all_icmp_to_mgmt_vulnscan" {
  count = "${var.enable_mgmt_vpc_access_to_all_vpcs}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "egress"
  protocol = "icmp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus.private_ip}/32"
  ]
  from_port = -1
  to_port = -1
}

# Allow all TCP to vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "bod_bastion_egress_all_tcp_to_mgmt_vulnscan" {
  count = "${var.enable_mgmt_vpc_access_to_all_vpcs}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus.private_ip}/32"
  ]
  from_port = 0
  to_port = 0
}

# Allow all UDP to vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "bod_bastion_egress_all_udp_to_mgmt_vulnscan" {
  count = "${var.enable_mgmt_vpc_access_to_all_vpcs}"

  security_group_id = "${aws_security_group.bod_bastion_sg.id}"
  type = "egress"
  protocol = "udp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus.private_ip}/32"
  ]
  from_port = 0
  to_port = 0
}
