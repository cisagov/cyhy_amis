resource "aws_route53_zone" "mgmt_private_zone" {
  count = "${var.enable_mgmt_vpc}"

  name = "${local.mgmt_private_domain}."
  vpc {
    vpc_id = "${aws_vpc.mgmt_vpc.id}"
  }
  tags = "${merge(var.tags, map("Name", "Management Private Zone"))}"
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "mgmt_router_A" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_private_zone.zone_id}"
  name = "router.${aws_route53_zone.mgmt_private_zone.name}"
  type = "A"
  ttl = 300
  records = [
    "${cidrhost(aws_subnet.mgmt_public_subnet.cidr_block, 1)}",
    "${cidrhost(aws_subnet.mgmt_private_subnet.cidr_block, 1)}"
  ]
}

resource "aws_route53_record" "mgmt_ns_A" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_private_zone.zone_id}"
  name = "ns.${aws_route53_zone.mgmt_private_zone.name}"
  type = "A"
  ttl = 300
  records = [
    "${cidrhost(aws_subnet.mgmt_public_subnet.cidr_block, 2)}",
    "${cidrhost(aws_subnet.mgmt_private_subnet.cidr_block, 2)}"
  ]
}

resource "aws_route53_record" "mgmt_reserved_A" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_private_zone.zone_id}"
  name = "reserved.${aws_route53_zone.mgmt_private_zone.name}"
  type = "A"
  ttl = 300
  records = [
    "${cidrhost(aws_subnet.mgmt_public_subnet.cidr_block, 3)}",
    "${cidrhost(aws_subnet.mgmt_private_subnet.cidr_block, 3)}"
  ]
}

resource "aws_route53_record" "mgmt_bastion_A" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_private_zone.zone_id}"
  name = "bastion.${aws_route53_zone.mgmt_private_zone.name}"
  type = "A"
  ttl = 300
  records = [
    "${aws_instance.mgmt_bastion.private_ip}"
  ]
}

resource "aws_route53_record" "mgmt_vulnscan_A" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_private_zone.zone_id}"
  name = "vulnscan1.${aws_route53_zone.mgmt_private_zone.name}"
  type = "A"
  ttl = 300
  records = [
    "${aws_instance.mgmt_nessus.private_ip}"
  ]
}

##################################
# Reverse records - public subnet
##################################

resource "aws_route53_zone" "mgmt_public_zone_reverse" {
  count = "${var.enable_mgmt_vpc}"

  # NOTE:  This assumes that we are using /24 blocks
  name = "${format("%s.%s.%s.in-addr.arpa.",
    element( split(".", aws_subnet.mgmt_public_subnet.cidr_block), 2),
    element( split(".", aws_subnet.mgmt_public_subnet.cidr_block), 1),
    element( split(".", aws_subnet.mgmt_public_subnet.cidr_block), 0),
  )}"

  vpc {
    vpc_id = "${aws_vpc.mgmt_vpc.id}"
  }
  tags = "${merge(var.tags, map("Name", "Management Public Reverse Zone"))}"
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "mgmt_rev_1_PTR" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_public_zone_reverse.zone_id}"
  name = "1.${aws_route53_zone.mgmt_public_zone_reverse.name}"
  type = "PTR"
  ttl = 300
  records = [
    "router.${local.mgmt_private_domain}."
  ]
}

resource "aws_route53_record" "mgmt_rev_2_PTR" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_public_zone_reverse.zone_id}"
  name = "2.${aws_route53_zone.mgmt_public_zone_reverse.name}"
  type = "PTR"
  ttl = 300
  records = [
    "ns.${local.mgmt_private_domain}."
  ]
}

resource "aws_route53_record" "mgmt_rev_3_PTR" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_public_zone_reverse.zone_id}"
  name = "3.${aws_route53_zone.mgmt_public_zone_reverse.name}"
  type = "PTR"
  ttl = 300
  records = [
    "reserved.${local.mgmt_private_domain}."
  ]
}

resource "aws_route53_record" "mgmt_rev_bastion_PTR" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_public_zone_reverse.zone_id}"
  name = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element( split(".", aws_instance.mgmt_bastion.private_ip), 3),
    element( split(".", aws_instance.mgmt_bastion.private_ip), 2),
    element( split(".", aws_instance.mgmt_bastion.private_ip), 1),
    element( split(".", aws_instance.mgmt_bastion.private_ip), 0),
  )}"
  type = "PTR"
  ttl = 300
  records = [
    "bastion.${local.mgmt_private_domain}."
  ]
}

##################################
# Reverse records - private subnet
##################################

resource "aws_route53_zone" "mgmt_private_zone_reverse" {
  count = "${var.enable_mgmt_vpc}"

  # NOTE:  This assumes that we are using /24 blocks
  name = "${format("%s.%s.%s.in-addr.arpa.",
    element( split(".", aws_subnet.mgmt_private_subnet.cidr_block), 2),
    element( split(".", aws_subnet.mgmt_private_subnet.cidr_block), 1),
    element( split(".", aws_subnet.mgmt_private_subnet.cidr_block), 0),
  )}"

  vpc {
    vpc_id = "${aws_vpc.mgmt_vpc.id}"
  }
  tags = "${merge(var.tags, map("Name", "Management Private Reverse Zone"))}"
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "mgmt_rev_nessus_PTR" {
  count = "${var.enable_mgmt_vpc}"

  zone_id = "${aws_route53_zone.mgmt_private_zone_reverse.zone_id}"
  name = "${format("%s.%s.%s.%s.in-addr.arpa.",
    element( split(".", aws_instance.mgmt_nessus.private_ip), 3),
    element( split(".", aws_instance.mgmt_nessus.private_ip), 2),
    element( split(".", aws_instance.mgmt_nessus.private_ip), 1),
    element( split(".", aws_instance.mgmt_nessus.private_ip), 0),
  )}"
  type = "PTR"
  ttl = 300
  records = [
    "vulnscan1.${local.mgmt_private_domain}."
  ]
}
