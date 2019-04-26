# Allow egress to the mongo database instance on the mongo port
resource "aws_security_group_rule" "adi_lambda_to_cyhy_mongo" {
  security_group_id = "${aws_security_group.adi_lambda_sg.id}"
  type = "egress"
  protocol = "tcp"
  cidr_blocks = [
    "${aws_instance.cyhy_mongo.private_ip}/32"
  ]
  from_port = "27017"
  to_port = "27017"
}
