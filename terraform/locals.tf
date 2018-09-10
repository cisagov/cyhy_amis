locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "production"
  production_workspace = "${replace(terraform.workspace, "production", "") != terraform.workspace}"

  # TODO no dynamic workspace until we can loop modules (see below)
  nmap_instance_count = "${local.production_workspace ? 48 : 1}"
  nessus_instance_count = "${local.production_workspace ? 3 : 1}"
  mongo_instance_count = "1"  # TODO: stuck at one until we can scale mongo_ec2

  # These are the ports via which trusted networks are allowed to
  # access the public-facing CyHy hosts
  cyhy_trusted_ingress_ports = [
    22,
    8834
  ]

  # These are the port ranges via which anyone is allowed to
  # access the public-facing CyHy hosts
  cyhy_untrusted_ingress_port_ranges = [
    {start = 1, end = 21},
    {start = 23, end = 8833},
    {start = 8835, end = 65535}
  ]

  # These are the ports on which the BOD Docker security group is
  # allowed to egress anywhere
  bod_docker_egress_anywhere_ports = [
    80,
    443,
    587
  ]

  # Pretty obvious what these are
  tcp_and_udp = [
    "tcp",
    "udp"
  ]
  ingress_and_egress = [
    "ingress",
    "egress"
  ]

  # domain name to use for internal DNS
  private_domain = "local"

  # zone to use for public DNS
  public_zone  = "cyber.dhs.gov"

  # subdomains to use in the public_zone.
  # to create records directly in the public_zone set to ""
  # otherwise it must end in a period
  public_subdomain = "cyhy."

  # DNS zone calculations based on requested instances
  # The numbers represent the count of IP addresses in a subnet
  # and are used by the cidrhost() function.
  # NOTE: there is an assumption that subnets are /24 in the reverse zone names

  # Port Scanners DNS entries
  first_port_scanner = 11
  count_port_scanner = "${local.nmap_instance_count}"

  # Vulnerability Scanners DNS entries
  first_vuln_scanner = 201
  count_vuln_scanner = "${local.nessus_instance_count}"

  # Database DNS entries
  first_database = 11
  count_database = "${local.mongo_instance_count}"

  # Singleton DNS entries
  the_reporter = 6  # there can be only one
  the_bastion = 254 # there can be only one
}
