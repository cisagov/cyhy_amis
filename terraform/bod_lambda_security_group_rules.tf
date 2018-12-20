# Allow HTTP, HTTPS, and SMTP (25, 467, 587) egress anywhere
resource "aws_security_group_rule" "lambda_anywhere" {
  count = "${length(local.bod_lambda_egress_anywhere_ports)}"

  security_group_id = "${aws_security_group.bod_lambda_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  from_port = "${local.bod_lambda_egress_anywhere_ports[count.index]}"
  to_port = "${local.bod_lambda_egress_anywhere_ports[count.index]}"
}

# Allow DNS egress to Google
resource "aws_security_group_rule" "lambda_dns_to_google" {
  count = "${length(local.tcp_and_udp)}"

  security_group_id = "${aws_security_group.bod_lambda_sg.id}"
  type = "egress"
  protocol = "${local.tcp_and_udp[count.index]}"
  cidr_blocks = [
    "8.8.8.8/32",
    "8.8.4.4/32"
  ]
  from_port = 53
  to_port = 53
}
