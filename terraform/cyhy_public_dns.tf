data "aws_route53_zone" "public_zone" {
  name = "${local.public_zone}"
}

resource "aws_route53_record" "bastion_pub_A" {
  zone_id = "${aws_route53_zone.private_zone.zone_id}"
  name    = "bastion.${terraform.workspace}.${local.public_subdomain}${data.aws_route53_zone.public_zone.name}"
  type    = "A"
  ttl     = 30
  records = [ "${aws_instance.cyhy_bastion.public_ip}" ]
}
