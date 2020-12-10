# Allow egress to the mongo database instance on the mongo port
resource "aws_security_group_rule" "adi_lambda_to_cyhy_mongo" {
  security_group_id = aws_security_group.adi_lambda_sg.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_mongo[0].private_ip}/32",
  ]
  from_port = var.assessment_data_import_db_port
  to_port   = var.assessment_data_import_db_port
}

# Allow HTTPS egress anywhere; needed to access AWS S3 bucket via boto3
resource "aws_security_group_rule" "adi_lambda_https_egress_anywhere" {
  security_group_id = aws_security_group.adi_lambda_sg.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
}
