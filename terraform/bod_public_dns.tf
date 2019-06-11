data "aws_route53_zone" "bod_public_zone" {
  name = local.bod_public_zone
}

resource "aws_route53_record" "bod_bastion_pub_A" {
  zone_id = data.aws_route53_zone.bod_public_zone.zone_id
  name    = "bastion.${terraform.workspace}.${local.bod_public_subdomain}${data.aws_route53_zone.bod_public_zone.name}"
  type    = "A"
  ttl     = 30
  records = [
    aws_instance.bod_bastion.public_ip,
  ]
}

