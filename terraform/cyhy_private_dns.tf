locals {
  # TODO no dynamic workspace until we can loop modules (see below)
  scanner_domain = "local."
}

resource "aws_route53_zone" "scanner_zone" {
  name = "${local.scanner_domain}"
}

resource "aws_route53_record" "router_A" {
  zone_id = "${aws_route53_zone.scanner_zone.zone_id}"
  name    = "router.${aws_route53_zone.scanner_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, 2)}" ]
}

resource "aws_route53_record" "ns_A" {
  zone_id = "${aws_route53_zone.scanner_zone.zone_id}"
  name    = "ns.${aws_route53_zone.scanner_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, 3)}" ]
}

resource "aws_route53_record" "reserved_A" {
  zone_id = "${aws_route53_zone.scanner_zone.zone_id}"
  name    = "reserved.${aws_route53_zone.scanner_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, 4)}" ]
}

resource "aws_route53_record" "portscan_A" {
  count = "${local.count_port_scanner}"
  zone_id = "${aws_route53_zone.scanner_zone.zone_id}"
  name    = "portscan${count.index + 1}.${aws_route53_zone.scanner_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_scanner_subnet.cidr_block, count.index + local.first_port_scanner)}" ]
}

# Reverse records

resource "aws_route53_zone" "scanner_zone_reverse" {
  name = "11.10.10.in-addr.arpa."
  vpc_id = "${aws_vpc.cyhy_vpc.id}"
}

resource "aws_route53_record" "rev_1_PTR" {
  zone_id = "${aws_route53_zone.scanner_zone_reverse.zone_id}"
  name    = "1.${aws_route53_zone.scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "router.${local.scanner_domain}" ]
}

resource "aws_route53_record" "rev_2_PTR" {
  zone_id = "${aws_route53_zone.scanner_zone_reverse.zone_id}"
  name    = "2.${aws_route53_zone.scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "ns.${local.scanner_domain}" ]
}

resource "aws_route53_record" "rev_3_PTR" {
  zone_id = "${aws_route53_zone.scanner_zone_reverse.zone_id}"
  name    = "3.${aws_route53_zone.scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "reserved.${local.scanner_domain}" ]
}

resource "aws_route53_record" "rev_PTR" {
  count = "${local.count_port_scanner}"
  zone_id = "${aws_route53_zone.scanner_zone_reverse.zone_id}"
  name    = "${local.first_port_scanner + count.index}.${aws_route53_zone.scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "portscan${count.index}.${local.scanner_domain}" ]
}
