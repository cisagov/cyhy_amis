# Allow ingress from the bastion security group via the ssh and Nessus
# ports
resource "aws_security_group_rule" "scanner_ingress_from_bastion_sg" {
  count = length(local.cyhy_trusted_ingress_ports)

  security_group_id        = aws_security_group.cyhy_scanner_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cyhy_bastion_sg.id
  from_port                = local.cyhy_trusted_ingress_ports[count.index]
  to_port                  = local.cyhy_trusted_ingress_ports[count.index]
}

# Allow ingress via ssh from the private security group
resource "aws_security_group_rule" "scanner_ingress_from_private_sg_via_ssh" {
  security_group_id        = aws_security_group.cyhy_scanner_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cyhy_private_sg.id
  from_port                = 22
  to_port                  = 22
}

# Allow ingress from anywhere via all other tcp ports
#
# IMPORTANT NOTE: The reason we allow this ingress is to avoid connection
# tracking in the stateful AWS security group for these ports.  Otherwise, our
# scan (nmap and Nessus) volume quickly causes the connection tracking table to
# fill up and our scans do not give valid results.
# "If a security group rule permits TCP or UDP flows for all traffic
# (0.0.0.0/0) and there is a corresponding rule in the other direction that
# permits all response traffic (0.0.0.0/0) for all ports (0-65535), then that
# flow of traffic is not tracked."
# "ICMP traffic is always tracked, regardless of rules."
# Above quotes from: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html#security-group-connection-tracking
# See also:  https://aerissecure.com/blog/vulnerability-scanning-from-aws/
resource "aws_security_group_rule" "scanner_ingress_anywhere_tcp" {
  count = length(local.cyhy_untrusted_ingress_port_ranges)

  security_group_id = aws_security_group.cyhy_scanner_sg.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port = local.cyhy_untrusted_ingress_port_ranges[count.index]["start"]
  to_port   = local.cyhy_untrusted_ingress_port_ranges[count.index]["end"]
}

# Allow ingress from anywhere via all udp ports
# See IMPORTANT NOTE above for explanation
resource "aws_security_group_rule" "scanner_ingress_anywhere_udp" {
  security_group_id = aws_security_group.cyhy_scanner_sg.id
  type              = "ingress"
  protocol          = "udp"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port = 0
  to_port   = 0
}

# Allow ingress from anywhere via all icmp ports
# See IMPORTANT NOTE above for explanation
resource "aws_security_group_rule" "scanner_ingress_anywhere_icmp" {
  security_group_id = aws_security_group.cyhy_scanner_sg.id
  type              = "ingress"
  protocol          = "icmp"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port = -1
  to_port   = -1
}

# Allow egress anywhere via all ports and protocols, since we're
# scanning
resource "aws_security_group_rule" "scanner_egress_anywhere" {
  security_group_id = aws_security_group.cyhy_scanner_sg.id
  type              = "egress"
  protocol          = "-1"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port = 0
  to_port   = 0
}

# Allow all TCP from vulnscanner instance in Management VPC,
# for internal scanning
resource "aws_security_group_rule" "scanner_ingress_all_tcp_from_mgmt_vulnscan" {
  count = var.enable_mgmt_vpc ? var.mgmt_nessus_instance_count : 0

  security_group_id = aws_security_group.cyhy_scanner_sg.id
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.mgmt_nessus[count.index].private_ip}/32",
  ]
  from_port = 0
  to_port   = 65535
}
