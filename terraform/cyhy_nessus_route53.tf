# Public DNS records
resource "aws_route53_record" "cyhy_nessus_pub_A" {
  count    = var.nessus_instance_count
  provider = aws.public_dns

  zone_id = data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.id
  name    = "vulnscan${count.index + 1}.${terraform.workspace}.${local.cyhy_public_subdomain}${data.terraform_remote_state.dns.outputs.cyber_dhs_gov_zone.name}"
  type    = "A"
  ttl     = 30
  records = [
    local.nessus_public_ips[count.index],
  ]
}

# Private DNS records
resource "aws_route53_record" "cyhy_vulnscan_A" {
  count   = local.count_vuln_scanner
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.cyhy_nessus[count.index].private_ip,
  ]
}

resource "aws_route53_record" "cyhy_rev_vulnscan_PTR" {
  count   = local.count_vuln_scanner
  zone_id = aws_route53_zone.cyhy_scanner_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      3,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      2,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      1,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nessus[count.index].private_ip,
      ),
      0,
    ),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}",
  ]
}
