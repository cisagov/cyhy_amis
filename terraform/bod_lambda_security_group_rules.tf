# Allow HTTP, HTTPS, and SMTP (25, 467, 587) egress anywhere
resource "aws_security_group_rule" "lambda_anywhere" {
  count = length(local.bod_lambda_egress_anywhere_ports)

  security_group_id = aws_security_group.bod_lambda_sg.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port = local.bod_lambda_egress_anywhere_ports[count.index]
  to_port   = local.bod_lambda_egress_anywhere_ports[count.index]
}
