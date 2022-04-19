# Private DNS records
resource "aws_route53_record" "mgmt_vulnscan_A" {
  count = var.enable_mgmt_vpc ? local.count_mgmt_vuln_scanner : 0

  zone_id = aws_route53_zone.mgmt_private_zone[0].zone_id
  name    = "vulnscan${count.index + 1}.${aws_route53_zone.mgmt_private_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.mgmt_nessus[count.index].private_ip,
  ]
}

resource "aws_route53_record" "mgmt_rev_nessus_PTR" {
  count = var.enable_mgmt_vpc ? local.count_mgmt_vuln_scanner : 0

  zone_id = aws_route53_zone.mgmt_private_zone_reverse[0].zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.mgmt_nessus[count.index].private_ip), 3),
    element(split(".", aws_instance.mgmt_nessus[count.index].private_ip), 2),
    element(split(".", aws_instance.mgmt_nessus[count.index].private_ip), 1),
    element(split(".", aws_instance.mgmt_nessus[count.index].private_ip), 0),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "vulnscan${count.index + 1}.${aws_route53_zone.mgmt_private_zone[0].name}",
  ]
}
