resource "aws_route53_zone" "cyber_zone" {
  name = "cyber.dhs.gov."

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "root_A" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = aws_route53_zone.cyber_zone.name
  type    = "A"

  alias {
    name                   = "d3nie9z8rrasif.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_AAAA" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = aws_route53_zone.cyber_zone.name
  type    = "AAAA"

  alias {
    name                   = "d3nie9z8rrasif.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_CAA" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = aws_route53_zone.cyber_zone.name
  type    = "CAA"
  ttl     = 300
  records = [
    "0 issue \"letsencrypt.org\"",
    "0 issue \"amazon.com\"",
    "0 issuewild \";\"",
    "0 iodef \"mailto:NCATSSecurity@hq.dhs.gov\"",
  ]
}

# This DNS record gives Amazon Certificate Manager permission to
# generate certificates for rules.ncats.cyber.dhs.gov
resource "aws_route53_record" "root_acm_rules_CNAME" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "_724d852f42d6b10ed1c6ab4135301ef6.rules.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "CNAME"
  ttl     = 60
  records = [
    "_548e9cb4a195b3c2a5410a9ff88fcda3.acm-validations.aws",
  ]
}

resource "aws_route53_record" "root_MX" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = aws_route53_zone.cyber_zone.name
  type    = "MX"
  ttl     = 300
  records = ["10 inbound-smtp.us-east-1.amazonaws.com"]
}

# NS and SOA records are assigned at zone creation and should not be modified
# If you do accidentally bork one, the values can be recovered...
# See: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/SOA-NSrecords.html

# resource "aws_route53_record" "root_NS" {
#   zone_id = "${aws_route53_zone.cyber_zone.zone_id}"
#   name    = "${aws_route53_zone.cyber_zone.name}"
#   type    = "NS"
#   ttl     = 172800
#   records = [ "ns-1930.awsdns-49.co.uk.",
#               "ns-237.awsdns-29.com.",
#               "ns-1358.awsdns-41.org.",
#               "ns-920.awsdns-51.net."
#             ]
# }
#
# resource "aws_route53_record" "root_SOA" {
#   zone_id = "${aws_route53_zone.cyber_zone.zone_id}"
#   name    = "${aws_route53_zone.cyber_zone.name}"
#   type    = "SOA"
#   ttl     = 900
#   records = [ "ns-1930.awsdns-49.co.uk. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400" ]
# }

resource "aws_route53_record" "root_SPF" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = aws_route53_zone.cyber_zone.name
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "_amazonses_TXT" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "_amazonses.${aws_route53_zone.cyber_zone.name}"
  type    = "TXT"
  ttl     = 60
  records = ["tOxXTap6jGLn6/VnBnget7lrXW+TxZTyTdOhm8LbM/Y="]
}

resource "aws_route53_record" "_dmarc_TXT" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "_dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "TXT"
  ttl     = 1800
  records = ["v=DMARC1; p=reject; sp=reject; adkim=s; aspf=r; rua=mailto:reports@dmarc.cyber.dhs.gov; rf=afrf; pct=100; ri=86400"]
}

resource "aws_route53_record" "dmarc_MX" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "MX"
  ttl     = 1800
  records = ["10 inbound-smtp.us-east-1.amazonaws.com"]
}

resource "aws_route53_record" "_amazonses_dmarc_TXT" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "_amazonses.dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "TXT"
  ttl     = 60
  records = ["CV4Ex6gYlJutTAnA8xkQa0hk3toSRuFvmibJ0sRiAWw="]
}

resource "aws_route53_record" "wildcard_report_dmarc_TXT" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "*._report._dmarc.dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1"]
}

resource "aws_route53_record" "dkim1_dmarc_CNAME" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "6na6lcj7onl5bco4ytfj4ud7p6t7kvtp._domainkey.dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["6na6lcj7onl5bco4ytfj4ud7p6t7kvtp.dkim.amazonses.com"]
}

resource "aws_route53_record" "dkim2_dmarc_CNAME" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "nsbndtrubsyckjqnb4wkv6xdkrqe3dk5._domainkey.dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["nsbndtrubsyckjqnb4wkv6xdkrqe3dk5.dkim.amazonses.com"]
}

resource "aws_route53_record" "dkim3_dmarc_CNAME" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "yhfkaco3ukhtbowt2bdvfz5czwuofitm._domainkey.dmarc.${aws_route53_zone.cyber_zone.name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["yhfkaco3ukhtbowt2bdvfz5czwuofitm.dkim.amazonses.com"]
}

resource "aws_route53_record" "drop_ncats_A" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "drop.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "A"
  ttl     = 60
  records = ["64.69.57.40"]
}

resource "aws_route53_record" "fw01_ncats_A" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "fw01.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "A"
  ttl     = 300
  records = ["64.69.57.3"]
}

resource "aws_route53_record" "fw02_ncats_A" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "fw02.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "A"
  ttl     = 300
  records = ["64.69.57.4"]
}

resource "aws_route53_record" "vip_ncats_A" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "vip.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "A"
  ttl     = 300
  records = ["64.69.57.2"]
}

resource "aws_route53_record" "vpn_ncats_CNAME" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "vpn.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "CNAME"
  ttl     = 300
  records = ["vip.ncats.cyber.dhs.gov"]
}

resource "aws_route53_record" "rr_CNAME" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "rr.${aws_route53_zone.cyber_zone.name}"
  type    = "CNAME"
  ttl     = 60
  records = ["rr.cyber.dhs.gov.s3-website-us-east-1.amazonaws.com"]
}

resource "aws_route53_record" "rules_ncats_A" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "rules.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "A"

  alias {
    name                   = "d35iq78wt3hgdh.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "rules_ncats_AAAA" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "rules.ncats.${aws_route53_zone.cyber_zone.name}"
  type    = "AAAA"

  alias {
    name                   = "d35iq78wt3hgdh.cloudfront.net."
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "mail_MX" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "mail.${aws_route53_zone.cyber_zone.name}"
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.us-east-1.amazonses.com"]
}

resource "aws_route53_record" "mail_SPF" {
  zone_id = aws_route53_zone.cyber_zone.zone_id
  name    = "mail.${aws_route53_zone.cyber_zone.name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com -all"]
}
