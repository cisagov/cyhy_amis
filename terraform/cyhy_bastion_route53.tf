# Public DNS records
resource "aws_route53_record" "cyhy_bastion_pub_A" {
  provider = aws.public_dns

  zone_id = data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.id
  name    = "bastion.${terraform.workspace}.${local.cyhy_public_subdomain}${data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.name}"
  type    = "A"
  ttl     = 30
  records = [
    aws_instance.cyhy_bastion.public_ip,
  ]
}

# Private DNS records
resource "aws_route53_record" "cyhy_bastion_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "bastion.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.cyhy_bastion.private_ip,
  ]
}

resource "aws_route53_record" "cyhy_rev_bastion_PTR" {
  zone_id = aws_route53_zone.cyhy_public_private_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_bastion.private_ip), 3),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 2),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 1),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 0),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "bastion.${aws_route53_zone.cyhy_private_zone.name}",
  ]
}
