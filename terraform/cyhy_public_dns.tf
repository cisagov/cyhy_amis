data "aws_route53_zone" "cyhy_public_zone" {
  name = local.cyhy_public_zone
}

resource "aws_route53_record" "cyhy_bastion_pub_A" {
  zone_id = data.aws_route53_zone.cyhy_public_zone.zone_id
  name    = "bastion.${terraform.workspace}.${local.cyhy_public_subdomain}${data.aws_route53_zone.cyhy_public_zone.name}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.cyhy_bastion.public_ip]
}

