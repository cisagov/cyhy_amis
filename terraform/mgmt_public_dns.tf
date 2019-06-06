data "aws_route53_zone" "mgmt_public_zone" {
  count = var.enable_mgmt_vpc ? 1 : 0

  name = local.mgmt_public_zone
}

resource "aws_route53_record" "mgmt_bastion_pub_A" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = data.aws_route53_zone.mgmt_public_zone[0].zone_id
  name    = "bastion.${terraform.workspace}.${local.mgmt_public_subdomain}${data.aws_route53_zone.mgmt_public_zone[0].name}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.mgmt_bastion[0].public_ip]
}

