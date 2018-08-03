resource "aws_vpc_peering_connection" "peering_connection_to_cyhy" {
  vpc_id = "${aws_vpc.bod_vpc.id}"
  peer_vpc_id = "${data.aws_vpc.cyhy_vpc.id}"
  auto_accept = true

  tags = "${merge(var.tags, map("Name", "CyHy and BOD 18-01"))}"
}

resource "aws_vpc_peering_connection_options" "peering_connection_to_cyhy" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peering_connection_to_cyhy.id}"

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}
