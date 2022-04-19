# Private DNS records
resource "aws_route53_record" "cyhy_dashboard_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "dashboard.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.cyhy_dashboard.private_ip,
  ]
}

resource "aws_route53_record" "cyhy_rev_dashboard_PTR" {
  zone_id = aws_route53_zone.cyhy_public_private_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 3),
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 2),
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 1),
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 0),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "dashboard.${aws_route53_zone.cyhy_private_zone.name}",
  ]
}
