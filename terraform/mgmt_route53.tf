resource "aws_route53_zone" "mgmt_private_zone" {
  count = var.enable_mgmt_vpc ? 1 : 0

  name = "${local.mgmt_private_domain}."
  vpc {
    vpc_id = aws_vpc.mgmt_vpc[0].id
  }

  vpc {
    vpc_id = aws_vpc.cyhy_vpc.id
  }

  vpc {
    vpc_id = aws_vpc.bod_vpc.id
  }

  # Because we're conditionally associating the CyHy and BOD VPCs with
  # this zone using the aws_route53_zone_association resources below,
  # this lifecycle bit is required.  See
  # https://www.terraform.io/docs/providers/aws/r/route53_zone_association.html
  lifecycle {
    ignore_changes = [vpc]
  }

  tags = { "Name" = "Management Private Zone" }

  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "mgmt_router_A" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_private_zone[0].zone_id
  name    = "router.${aws_route53_zone.mgmt_private_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.mgmt_public_subnet[0].cidr_block, 1),
    cidrhost(aws_subnet.mgmt_private_subnet[0].cidr_block, 1),
  ]
}

resource "aws_route53_record" "mgmt_ns_A" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_private_zone[0].zone_id
  name    = "ns.${aws_route53_zone.mgmt_private_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.mgmt_public_subnet[0].cidr_block, 2),
    cidrhost(aws_subnet.mgmt_private_subnet[0].cidr_block, 2),
  ]
}

resource "aws_route53_record" "mgmt_reserved_A" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_private_zone[0].zone_id
  name    = "reserved.${aws_route53_zone.mgmt_private_zone[0].name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.mgmt_public_subnet[0].cidr_block, 3),
    cidrhost(aws_subnet.mgmt_private_subnet[0].cidr_block, 3),
  ]
}

##################################
# Reverse records - public subnet
##################################

resource "aws_route53_zone" "mgmt_public_zone_reverse" {
  count = var.enable_mgmt_vpc ? 1 : 0

  # NOTE:  This assumes that we are using /24 blocks
  name = format(
    "%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.mgmt_public_subnet[0].cidr_block), 2),
    element(split(".", aws_subnet.mgmt_public_subnet[0].cidr_block), 1),
    element(split(".", aws_subnet.mgmt_public_subnet[0].cidr_block), 0),
  )

  vpc {
    vpc_id = aws_vpc.mgmt_vpc[0].id
  }

  tags = { "Name" = "Management Public Reverse Zone" }

  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "mgmt_rev_1_PTR" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_public_zone_reverse[0].zone_id
  name    = "1.${aws_route53_zone.mgmt_public_zone_reverse[0].name}"
  type    = "PTR"
  ttl     = 300
  records = [
    "router.${aws_route53_zone.mgmt_private_zone[0].name}",
  ]
}

resource "aws_route53_record" "mgmt_rev_2_PTR" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_public_zone_reverse[0].zone_id
  name    = "2.${aws_route53_zone.mgmt_public_zone_reverse[0].name}"
  type    = "PTR"
  ttl     = 300
  records = [
    "ns.${aws_route53_zone.mgmt_private_zone[0].name}",
  ]
}

resource "aws_route53_record" "mgmt_rev_3_PTR" {
  count = var.enable_mgmt_vpc ? 1 : 0

  zone_id = aws_route53_zone.mgmt_public_zone_reverse[0].zone_id
  name    = "3.${aws_route53_zone.mgmt_public_zone_reverse[0].name}"
  type    = "PTR"
  ttl     = 300
  records = [
    "reserved.${aws_route53_zone.mgmt_private_zone[0].name}",
  ]
}

##################################
# Reverse records - private subnet
##################################

resource "aws_route53_zone" "mgmt_private_zone_reverse" {
  count = var.enable_mgmt_vpc ? 1 : 0

  # NOTE:  This assumes that we are using /24 blocks
  name = format(
    "%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.mgmt_private_subnet[0].cidr_block), 2),
    element(split(".", aws_subnet.mgmt_private_subnet[0].cidr_block), 1),
    element(split(".", aws_subnet.mgmt_private_subnet[0].cidr_block), 0),
  )

  vpc {
    vpc_id = aws_vpc.mgmt_vpc[0].id
  }

  tags = { "Name" = "Management Private Reverse Zone" }

  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}
