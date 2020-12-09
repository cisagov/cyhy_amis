resource "aws_route53_zone" "bod_private_zone" {
  name = "${local.bod_private_domain}."

  vpc {
    vpc_id = aws_vpc.bod_vpc.id
  }

  vpc {
    vpc_id = aws_vpc.cyhy_vpc.id
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
      "Name" = "BOD Private Zone"
    },
  )
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

# Also associate the management VPC, if it's present
resource "aws_route53_zone_association" "mgmt_bod" {
  count   = var.enable_mgmt_vpc ? 1 : 0
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  vpc_id  = aws_vpc.mgmt_vpc[0].id
}

resource "aws_route53_record" "bod_router_A" {
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  name    = "router.${aws_route53_zone.bod_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.bod_public_subnet.cidr_block, 1),
    cidrhost(aws_subnet.bod_docker_subnet.cidr_block, 1),
    cidrhost(aws_subnet.bod_lambda_subnet.cidr_block, 1),
  ]
}

resource "aws_route53_record" "bod_ns_A" {
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  name    = "ns.${aws_route53_zone.bod_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.bod_public_subnet.cidr_block, 2),
    cidrhost(aws_subnet.bod_docker_subnet.cidr_block, 2),
    cidrhost(aws_subnet.bod_lambda_subnet.cidr_block, 2),
  ]
}

resource "aws_route53_record" "bod_reserved_A" {
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  name    = "reserved.${aws_route53_zone.bod_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    cidrhost(aws_subnet.bod_public_subnet.cidr_block, 3),
    cidrhost(aws_subnet.bod_docker_subnet.cidr_block, 3),
    cidrhost(aws_subnet.bod_lambda_subnet.cidr_block, 3),
  ]
}

resource "aws_route53_record" "bod_bastion_A" {
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  name    = "bastion.${aws_route53_zone.bod_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.bod_bastion.private_ip,
  ]
}

resource "aws_route53_record" "bod_docker_A" {
  zone_id = aws_route53_zone.bod_private_zone.zone_id
  name    = "docker.${aws_route53_zone.bod_private_zone.name}"
  type    = "A"
  ttl     = 300
  records = [
    aws_instance.bod_docker.private_ip,
  ]
}

##################################
# Reverse records - public subnet
##################################

resource "aws_route53_zone" "bod_public_zone_reverse" {
  # NOTE:  This assumes that we are using /24 blocks
  name = format(
    "%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.bod_public_subnet.cidr_block), 2),
    element(split(".", aws_subnet.bod_public_subnet.cidr_block), 1),
    element(split(".", aws_subnet.bod_public_subnet.cidr_block), 0),
  )

  vpc {
    vpc_id = aws_vpc.bod_vpc.id
  }
  tags = merge(
    var.tags,
    {
      "Name" = "BOD Public Reverse Zone"
    },
  )
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "bod_rev_1_PTR" {
  zone_id = aws_route53_zone.bod_public_zone_reverse.zone_id
  name    = "1.${aws_route53_zone.bod_public_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [
    "router.${aws_route53_zone.bod_private_zone.name}",
  ]
}

resource "aws_route53_record" "bod_rev_2_PTR" {
  zone_id = aws_route53_zone.bod_public_zone_reverse.zone_id
  name    = "2.${aws_route53_zone.bod_public_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [
    "ns.${aws_route53_zone.bod_private_zone.name}",
  ]
}

resource "aws_route53_record" "bod_rev_3_PTR" {
  zone_id = aws_route53_zone.bod_public_zone_reverse.zone_id
  name    = "3.${aws_route53_zone.bod_public_zone_reverse.name}"
  type    = "PTR"
  ttl     = 300
  records = [
    "reserved.${aws_route53_zone.bod_private_zone.name}",
  ]
}

resource "aws_route53_record" "bod_rev_bastion_PTR" {
  zone_id = aws_route53_zone.bod_public_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.bod_bastion.private_ip), 3),
    element(split(".", aws_instance.bod_bastion.private_ip), 2),
    element(split(".", aws_instance.bod_bastion.private_ip), 1),
    element(split(".", aws_instance.bod_bastion.private_ip), 0),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "bastion.${aws_route53_zone.bod_private_zone.name}",
  ]
}

##################################
# Reverse records - private subnet
##################################

resource "aws_route53_zone" "bod_private_zone_reverse" {
  # NOTE:  This assumes that we are using /24 blocks
  name = format(
    "%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_subnet.bod_docker_subnet.cidr_block), 2),
    element(split(".", aws_subnet.bod_docker_subnet.cidr_block), 1),
    element(split(".", aws_subnet.bod_docker_subnet.cidr_block), 0),
  )

  vpc {
    vpc_id = aws_vpc.bod_vpc.id
  }
  tags = merge(
    var.tags,
    {
      "Name" = "BOD Private Reverse Zone"
    },
  )
  comment = "Terraform Workspace: ${lookup(var.tags, "Workspace", "Undefined")}"
}

resource "aws_route53_record" "bod_rev_docker_PTR" {
  zone_id = aws_route53_zone.bod_private_zone_reverse.zone_id
  name = format(
    "%s.%s.%s.%s.in-addr.arpa.",
    element(split(".", aws_instance.bod_docker.private_ip), 3),
    element(split(".", aws_instance.bod_docker.private_ip), 2),
    element(split(".", aws_instance.bod_docker.private_ip), 1),
    element(split(".", aws_instance.bod_docker.private_ip), 0),
  )

  type = "PTR"
  ttl  = 300
  records = [
    "docker.${aws_route53_zone.bod_private_zone.name}",
  ]
}
