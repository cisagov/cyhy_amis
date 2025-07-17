# Private DNS records
resource "aws_route53_record" "bod_docker_A" {
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  name    = "docker.${aws_route53_zone.bod_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.bod_docker.private_ip,
  ]
}

resource "aws_route53_record" "bod_rev_docker_PTR" {
  zone_id = aws_route53_zone.bod_private_zone_reverse.zone_id
  name = format(
    "%s.in-addr.arpa.",
    join(".", reverse(split(".", aws_instance.bod_docker.private_ip))),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "docker.${aws_route53_zone.bod_private_zone.name}",
  ]
}
