data "aws_route53_zone" "mgmt_public_zone" {
  name = "${local.mgmt_public_zone}"
}

resource "aws_route53_record" "mgmt_bastion_pub_A" {
  zone_id = "${data.aws_route53_zone.mgmt_public_zone.zone_id}"
  name    = "bastion.${terraform.workspace}.${local.mgmt_public_subdomain}${data.aws_route53_zone.mgmt_public_zone.name}"
  type    = "A"
  ttl     = 30
  records = [ "${aws_instance.mgmt_bastion.public_ip}" ]
}
