# Private DNS records
resource "aws_route53_record" "cyhy_portscan_A" {
  count   = local.count_port_scanner
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "portscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.cyhy_nmap[count.index].private_ip,
  ]
}

resource "aws_route53_record" "cyhy_rev_portscan_PTR" {
  count   = local.count_port_scanner
  zone_id = aws_route53_zone.cyhy_scanner_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(
      split(
        ".",
        aws_instance.cyhy_nmap[count.index].private_ip,
      ),
      3,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nmap[count.index].private_ip,
      ),
      2,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nmap[count.index].private_ip,
      ),
      1,
    ),
    element(
      split(
        ".",
        aws_instance.cyhy_nmap[count.index].private_ip,
      ),
      0,
    ),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "portscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}",
  ]
}
