resource "aws_route53_zone" "cyhy_private_zone" {
  name = "${local.cyhy_private_domain}."

  vpc {
    vpc_id = aws_vpc.cyhy_vpc.id
  }

  vpc {
    vpc_id = aws_vpc.bod_vpc.id
  }

  # Because we're conditionally associating the management VPC with
  # this zone using the aws_route53_zone_association resource below,
  # this lifecycle bit is required.  See
  # https://www.terraform.io/docs/providers/aws/r/route53_zone_association.html
  lifecycle {
    ignore_changes = [vpc]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Private Zone"
    },
  )
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

# Also associate the management VPC, if it's present
resource "aws_route53_zone_association" "mgmt_cyhy" {
  count   = var.enable_mgmt_vpc ? 1 : 0
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  vpc_id  = aws_vpc.mgmt_vpc[0].id
}

resource "aws_route53_record" "cyhy_router_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "router.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.cyhy_portscanner_subnet.cidr_block, 1),
    cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, 1),
  ]
}

resource "aws_route53_record" "cyhy_ns_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "ns.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.cyhy_portscanner_subnet.cidr_block, 2),
    cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, 2),
  ]
}

resource "aws_route53_record" "cyhy_reserved_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "reserved.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.cyhy_portscanner_subnet.cidr_block, 3),
    cidrhost(aws_subnet.cyhy_private_subnet.cidr_block, 3),
  ]
}

resource "aws_route53_record" "cyhy_bastion_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "bastion.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cyhy_bastion.private_ip]
}

resource "aws_route53_record" "cyhy_reporter_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "reporter.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cyhy_reporter.private_ip]
}

resource "aws_route53_record" "cyhy_database_A" {
  count   = local.count_database
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "database${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cyhy_mongo[0].private_ip]
}

resource "aws_route53_record" "cyhy_portscan_A" {
  count   = local.count_port_scanner
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "portscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cyhy_nmap[count.index].private_ip]
}

resource "aws_route53_record" "cyhy_vulnscan_A" {
  count   = local.count_vuln_scanner
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cyhy_nessus[count.index].private_ip]
}

resource "aws_route53_record" "cyhy_dashboard_A" {
  zone_id = aws_route53_zone.cyhy_private_zone.zone_id
  name    = "dashboard.${aws_route53_zone.cyhy_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.cyhy_dashboard.private_ip]
}

#######################################################
# Reverse records - portscanner and vulnscanner subnets
#######################################################

resource "aws_route53_zone" "cyhy_scanner_zone_reverse" {
  # NOTE:  This assumes that we are using /24 blocks or smaller
  name = format(
    "%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.cyhy_portscanner_subnet.cidr_block), 2),
    element(split(".", aws_subnet.cyhy_portscanner_subnet.cidr_block), 1),
    element(split(".", aws_subnet.cyhy_portscanner_subnet.cidr_block), 0),
  )

  vpc {
    vpc_id = aws_vpc.cyhy_vpc.id
  }
  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Portcanner/Vulnscanner Reverse Zone"
    },
  )
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "cyhy_rev_1_PTR" {
  zone_id = aws_route53_zone.cyhy_scanner_zone_reverse.zone_id
  name    = "1.${aws_route53_zone.cyhy_scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = ["router.${aws_route53_zone.cyhy_private_zone.name}"]
}

resource "aws_route53_record" "cyhy_rev_2_PTR" {
  zone_id = aws_route53_zone.cyhy_scanner_zone_reverse.zone_id
  name    = "2.${aws_route53_zone.cyhy_scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = ["ns.${aws_route53_zone.cyhy_private_zone.name}"]
}

resource "aws_route53_record" "cyhy_rev_3_PTR" {
  zone_id = aws_route53_zone.cyhy_scanner_zone_reverse.zone_id
  name    = "3.${aws_route53_zone.cyhy_scanner_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = ["reserved.${aws_route53_zone.cyhy_private_zone.name}"]
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

  type    = "PTR"
  ttl     = 300
  records = ["portscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"]
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

  type    = "PTR"
  ttl     = 300
  records = ["vulnscan${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"]
}

##############################################
# Reverse records - private and public subnets
##############################################

resource "aws_route53_zone" "cyhy_public_private_zone_reverse" {
  # NOTE:  This assumes that we are using /24 blocks or smaller
  name = format(
    "%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.cyhy_private_subnet.cidr_block), 2),
    element(split(".", aws_subnet.cyhy_private_subnet.cidr_block), 1),
    element(split(".", aws_subnet.cyhy_private_subnet.cidr_block), 0),
  )

  vpc {
    vpc_id = aws_vpc.cyhy_vpc.id
  }
  tags = merge(
    var.tags,
    {
      "Name" = "CyHy Public/Private Reverse Zone"
    },
  )
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "cyhy_rev_bastion_PTR" {
  zone_id = aws_route53_zone.cyhy_public_private_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_bastion.private_ip), 3),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 2),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 1),
    element(split(".", aws_instance.cyhy_bastion.private_ip), 0),
  )

  type    = "PTR"
  ttl     = 300
  records = ["bastion.${aws_route53_zone.cyhy_private_zone.name}"]
}

resource "aws_route53_record" "cyhy_rev_reporter_PTR" {
  zone_id = aws_route53_zone.cyhy_public_private_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_reporter.private_ip), 3),
    element(split(".", aws_instance.cyhy_reporter.private_ip), 2),
    element(split(".", aws_instance.cyhy_reporter.private_ip), 1),
    element(split(".", aws_instance.cyhy_reporter.private_ip), 0),
  )

  type    = "PTR"
  ttl     = 300
  records = ["reporter.${aws_route53_zone.cyhy_private_zone.name}"]
}

resource "aws_route53_record" "cyhy_rev_database_PTR" {
  count   = local.count_database
  zone_id = aws_route53_zone.cyhy_public_private_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.cyhy_mongo[0].private_ip), 3),
    element(split(".", aws_instance.cyhy_mongo[0].private_ip), 2),
    element(split(".", aws_instance.cyhy_mongo[0].private_ip), 1),
    element(split(".", aws_instance.cyhy_mongo[0].private_ip), 0),
  )

  type    = "PTR"
  ttl     = 300
  records = ["database${count.index + 1}.${aws_route53_zone.cyhy_private_zone.name}"]
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

  type    = "PTR"
  ttl     = 300
  records = ["dashboard.${aws_route53_zone.cyhy_private_zone.name}"]
}
