resource "aws_route53_zone" "cyhy_private_zone" {
  name = "${local.cyhy_private_domain}."
  vpc {
    vpc_id = "${aws_vpc.cyhy_vpc.id}"
  }
  tags = "${merge(var.tags, map("Name", "CyHy Private Zone"))}"
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "cyhy_router_A" {
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "router.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_portscanner_subnet.cidr_block, 1)}",
              "${cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, 1)}"]
}

resource "aws_route53_record" "cyhy_ns_A" {
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "ns.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_portscanner_subnet.cidr_block, 2)}",
              "${cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, 2)}"]
}

resource "aws_route53_record" "cyhy_reserved_A" {
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "reserved.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${cidrhost(aws_subnet.cyhy_portscanner_subnet.cidr_block, 3)}",
              "${cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, 3)}"]
}

resource "aws_route53_record" "cyhy_bastion_A" {
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "bastion.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${aws_instance.cyhy_bastion.private_ip}" ]
}

resource "aws_route53_record" "cyhy_reporter_A" {
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "reporter.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${aws_instance.cyhy_reporter.private_ip}"]
}

resource "aws_route53_record" "cyhy_database_A" {
  count = "${local.count_database}"
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "database${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${aws_instance.cyhy_mongo.private_ip}" ]
}

resource "aws_route53_record" "cyhy_portscan_A" {
  count = "${local.count_port_scanner}"
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "portscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${aws_instance.cyhy_nmap.*.private_ip[count.index]}" ]
}

resource "aws_route53_record" "cyhy_vulnscan_A" {
  count = "${local.count_vuln_scanner}"
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${aws_instance.cyhy_nessus.*.private_ip[count.index]}" ]
}

resource "aws_route53_record" "cyhy_dashboard_A" {
  zone_id = "${aws_route53_zone.cyhy_private_zone.zone_id}"
  name    = "dashboard.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [ "${aws_instance.cyhy_dashboard.private_ip}"]
}

#######################################################
# Reverse records - portscanner and vulnscanner subnets
#######################################################

resource "aws_route53_zone" "cyhy_scanner_zone_reverse" {
  # NOTE:  This assumes that we are using /24 blocks or smaller
  name = "${format("%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.cyhy_portscanner_subnet.cidr_block), 2),
    element(split(".", aws_subnet.cyhy_portscanner_subnet.cidr_block), 1),
    element(split(".", aws_subnet.cyhy_portscanner_subnet.cidr_block), 0),
  )}"

  vpc {
    vpc_id = "${aws_vpc.cyhy_vpc.id}"
  }
  tags = "${merge(var.tags, map("Name", "CyHy Portcanner/Vulnscanner Reverse Zone"))}"
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "cyhy_rev_1_PTR" {
  zone_id = "${aws_route53_zone.cyhy_scanner_zone_reverse.zone_id}"
  name    = "1.${aws_route53_zone.cyhy_scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "router.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_2_PTR" {
  zone_id = "${aws_route53_zone.cyhy_scanner_zone_reverse.zone_id}"
  name    = "2.${aws_route53_zone.cyhy_scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "ns.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_3_PTR" {
  zone_id = "${aws_route53_zone.cyhy_scanner_zone_reverse.zone_id}"
  name    = "3.${aws_route53_zone.cyhy_scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [ "reserved.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_portscan_PTR" {
  count = "${local.count_port_scanner}"
  zone_id = "${aws_route53_zone.cyhy_scanner_zone_reverse.zone_id}"
  name    = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", element(aws_instance.cyhy_nmap.*.private_ip, count.index)), 3),
    element(split(".", element(aws_instance.cyhy_nmap.*.private_ip, count.index)), 2),
    element(split(".", element(aws_instance.cyhy_nmap.*.private_ip, count.index)), 1),
    element(split(".", element(aws_instance.cyhy_nmap.*.private_ip, count.index)), 0),
  )}"
  type    = "PTR"
  ttl     = 300
  records = [ "portscan${count.index + 1}.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_vulnscan_PTR" {
  count = "${local.count_vuln_scanner}"
  zone_id = "${aws_route53_zone.cyhy_scanner_zone_reverse.zone_id}"
  name    = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", element(aws_instance.cyhy_nessus.*.private_ip, count.index)), 3),
    element(split(".", element(aws_instance.cyhy_nessus.*.private_ip, count.index)), 2),
    element(split(".", element(aws_instance.cyhy_nessus.*.private_ip, count.index)), 1),
    element(split(".", element(aws_instance.cyhy_nessus.*.private_ip, count.index)), 0),
  )}"
  type    = "PTR"
  ttl     = 300
  records = [ "vulnscan${count.index + 1}.${local.cyhy_private_domain}." ]
}

##############################################
# Reverse records - private and public subnets
##############################################

resource "aws_route53_zone" "cyhy_public_private_zone_reverse" {
  # NOTE:  This assumes that we are using /24 blocks or smaller
  name = "${format("%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.cyhy_private_subnet.cidr_block), 2),
    element(split(".", aws_subnet.cyhy_private_subnet.cidr_block), 1),
    element(split(".", aws_subnet.cyhy_private_subnet.cidr_block), 0),
  )}"

  vpc {
    vpc_id = "${aws_vpc.cyhy_vpc.id}"
  }
  tags = "${merge(var.tags, map("Name", "CyHy Public/Private Reverse Zone"))}"
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "cyhy_rev_bastion_PTR" {
  zone_id = "${aws_route53_zone.cyhy_public_private_zone_reverse.zone_id}"
  name    = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_bastion.private_ip), 3),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 2),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 1),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 0),
  )}"
  type    = "PTR"
  ttl     = 300
  records = [ "bastion.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_reporter_PTR" {
  zone_id = "${aws_route53_zone.cyhy_public_private_zone_reverse.zone_id}"
  name    = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_reporter.private_ip), 3),
    element(split(".", aws_instance.cyhy_reporter.private_ip), 2),
    element(split(".", aws_instance.cyhy_reporter.private_ip), 1),
    element(split(".", aws_instance.cyhy_reporter.private_ip), 0),
  )}"
  type    = "PTR"
  ttl     = 300
  records = [ "reporter.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_database_PTR" {
  count = "${local.count_database}"
  zone_id = "${aws_route53_zone.cyhy_public_private_zone_reverse.zone_id}"
  name    = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_mongo.private_ip), 3),
    element(split(".", aws_instance.cyhy_mongo.private_ip), 2),
    element(split(".", aws_instance.cyhy_mongo.private_ip), 1),
    element(split(".", aws_instance.cyhy_mongo.private_ip), 0),
  )}"
  type    = "PTR"
  ttl     = 300
  records = [ "database${count.index + 1}.${local.cyhy_private_domain}." ]
}

resource "aws_route53_record" "cyhy_rev_dashboard_PTR" {
  zone_id = "${aws_route53_zone.cyhy_public_private_zone_reverse.zone_id}"
  name    = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 3),
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 2),
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 1),
    element(split(".", aws_instance.cyhy_dashboard.private_ip), 0),
  )}"
  type    = "PTR"
  ttl     = 300
  records = [ "dashboard.${local.cyhy_private_domain}." ]
}
