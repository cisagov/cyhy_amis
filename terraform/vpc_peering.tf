resource "aws_vpc_peering_connection" "cyhy_bod_peering_connection" {
  vpc_id      = aws_vpc.bod_vpc.id
  peer_vpc_id = aws_vpc.cyhy_vpc.id
  auto_accept = true

  tags = { "Name" = "CyHy and BOD 18-01" }
}

resource "aws_vpc_peering_connection_options" "cyhy_bod_peering_connection" {
  vpc_peering_connection_id = aws_vpc_peering_connection.cyhy_bod_peering_connection.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection" "cyhy_mgmt_peering_connection" {
  count = var.enable_mgmt_vpc ? 1 : 0

  vpc_id      = aws_vpc.mgmt_vpc[0].id
  peer_vpc_id = aws_vpc.cyhy_vpc.id
  auto_accept = true

  tags = { "Name" = "CyHy and Management" }
}

resource "aws_vpc_peering_connection_options" "cyhy_mgmt_peering_connection" {
  count = var.enable_mgmt_vpc ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection.cyhy_mgmt_peering_connection[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection" "bod_mgmt_peering_connection" {
  count = var.enable_mgmt_vpc ? 1 : 0

  vpc_id      = aws_vpc.mgmt_vpc[0].id
  peer_vpc_id = aws_vpc.bod_vpc.id
  auto_accept = true

  tags = { "Name" = "BOD 18-01 and Management" }
}

resource "aws_vpc_peering_connection_options" "bod_mgmt_peering_connection" {
  count = var.enable_mgmt_vpc ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection.bod_mgmt_peering_connection[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}
