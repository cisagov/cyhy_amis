# Public DNS records
resource "aws_route53_record" "mgmt_bastion_pub_A" {
  provider = aws.public_dns
  count    = var.enable_mgmt_vpc ? 1 : 0

  zone_id = data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.id
  name    = "bastion.${terraform.workspace}.${local.mgmt_public_subdomain}${data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.name}"
  type    = "A"
  ttl     = 30
  records = [
    aws_instance.mgmt_bastion[0].public_ip,
  ]
}

# Private DNS records
resource "aws_route53_record" "mgmt_bastion_A" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_private_zone[0].zone_id
  name    = "bastion.${aws_route53_zone.mgmt_private_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.mgmt_bastion[0].private_ip,
  ]
}

resource "aws_route53_record" "mgmt_rev_bastion_PTR" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_public_zone_reverse[0].zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.mgmt_bastion[0].private_ip), 3),
    element(split(".", aws_instance.mgmt_bastion[0].private_ip), 2),
    element(split(".", aws_instance.mgmt_bastion[0].private_ip), 1),
    element(split(".", aws_instance.mgmt_bastion[0].private_ip), 0),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "bastion.${aws_route53_zone.mgmt_private_zone[0].name}",
  ]
}
