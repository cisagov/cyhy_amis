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
