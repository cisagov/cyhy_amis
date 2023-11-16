# Allow egress to the CyHy MongoDB instance on the configured port
resource "aws_security_group_rule" "lambda_egress_to_mongo_via_mongo" {
  security_group_id = aws_security_group.lambda_mongodb_sg.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_mongo[0].private_ip}/32",
  ]
  from_port = 27017
  to_port   = 27017
}

# Allow HTTPS egress anywhere
resource "aws_security_group_rule" "lambda_https_egress_to_anywhere" {
  security_group_id = aws_security_group.lambda_https_sg.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}
