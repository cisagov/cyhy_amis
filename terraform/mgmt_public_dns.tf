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
