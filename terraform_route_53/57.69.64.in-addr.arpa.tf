resource "aws_route53_zone" "reverse_zone" {
  name = "57.69.64.in-addr.arpa."

  lifecycle {
    prevent_destroy = true
  }
}

# NS and SOA records are assigned at zone creation and should not be modified
# If you do accidentally bork one, the values can be recovered...
# See: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html

resource "aws_route53_record" "rev_1_PTR" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "1.${aws_route53_zone.reverse_zone.name}"
  type    = "PTR"
  ttl     = 300
  records = ["router.ncats.cyber.dhs.gov."]
}

resource "aws_route53_record" "rev_2_PTR" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "2.${aws_route53_zone.reverse_zone.name}"
  type    = "PTR"
  ttl     = 300
  records = ["vip.ncats.cyber.dhs.gov."]
}

resource "aws_route53_record" "rev_3_PTR" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "3.${aws_route53_zone.reverse_zone.name}"
  type    = "PTR"
  ttl     = 300
  records = ["fw01.ncats.cyber.dhs.gov."]
}

resource "aws_route53_record" "rev_4_PTR" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "4.${aws_route53_zone.reverse_zone.name}"
  type    = "PTR"
  ttl     = 300
  records = ["fw02.ncats.cyber.dhs.gov."]
}
