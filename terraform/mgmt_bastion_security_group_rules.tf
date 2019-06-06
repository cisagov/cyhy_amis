# Allow ingress from trusted networks via ssh
resource "aws_security_group_rule" "mgmt_bastion_ingress_from_trusted_via_ssh" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.trusted_ingress_networks_ipv4

  # ipv6_cidr_blocks = "${var.trusted_ingress_networks_ipv6}"
  from_port = 22
  to_port   = 22
}

# Allow ingress from the bastion's public IP via ssh.
#
# We need this because Ansible uses the ssh proxy even when connecting
# to the bastion.
resource "aws_security_group_rule" "mgmt_bastion_self_ingress" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_bastion[0].public_ip}/32",
  ]
  from_port = 22
  to_port   = 22
}

# Allow egress to the bastion's public IP via ssh.
#
# We need this because Ansible uses the ssh proxy even when connecting
# to the bastion.
resource "aws_security_group_rule" "mgmt_bastion_self_egress" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_bastion[0].public_ip}/32",
  ]
  from_port = 22
  to_port   = 22
}

# Allow egress via ssh and Nessus to the scanner security group
resource "aws_security_group_rule" "mgmt_bastion_egress_to_scanner_sg_via_trusted_ports" {
  count = var.enable_mgmt_vpc * length(local.mgmt_trusted_ingress_ports)

  security_group_id        = aws_security_group.mgmt_bastion_sg[0].id
  type                     = "egress"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mgmt_scanner_sg[0].id
  from_port                = local.mgmt_trusted_ingress_ports[count.index]
  to_port                  = local.mgmt_trusted_ingress_ports[count.index]
}

# Allow all ICMP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "mgmt_bastion_ingress_all_icmp_from_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "ingress"
  protocol          = "icmp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[0].private_ip}/32",
  ]
  from_port = -1
  to_port   = -1
}

# Allow all TCP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "mgmt_bastion_ingress_all_tcp_from_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[0].private_ip}/32",
  ]
  from_port = 0
  to_port   = 65535
}

# Allow all UDP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "mgmt_bastion_ingress_all_udp_from_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[0].private_ip}/32",
  ]
  from_port = 0
  to_port   = 65535
}

# Allow all ICMP to vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "mgmt_bastion_egress_all_icmp_to_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "egress"
  protocol          = "icmp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[0].private_ip}/32",
  ]
  from_port = -1
  to_port   = -1
}

# Allow all TCP to vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "mgmt_bastion_egress_all_tcp_to_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[0].private_ip}/32",
  ]
  from_port = 0
  to_port   = 65535
}

# Allow all UDP to vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "mgmt_bastion_egress_all_udp_to_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc

  security_group_id = aws_security_group.mgmt_bastion_sg[0].id
  type              = "egress"
  protocol          = "udp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[0].private_ip}/32",
  ]
  from_port = 0
  to_port   = 65535
}

