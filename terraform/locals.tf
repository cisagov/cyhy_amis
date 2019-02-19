locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "prod"
  production_workspace = "${replace(terraform.workspace, "prod", "") != terraform.workspace}"

  # Note: some locals are generated dynamically by the configure.py script and
  # are not part of this file.  e.g.; *_instance_count  Please run configure.py
  # to generate these in a separate file.

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
    21,
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
  cyhy_private_domain = "local"

  # domain name to use for internal DNS
  bod_private_domain = "local"

  # zone to use for public DNS
  cyhy_public_zone  = "ncats.cyber.dhs.gov"

  # zone to use for public DNS
  bod_public_zone  = "ncats.cyber.dhs.gov"

  # subdomains to use in the public_zone.
  # to create records directly in the public_zone set to ""
  # otherwise it must end in a period
  cyhy_public_subdomain = "cyhy."

  # subdomains to use in the public_zone.
  # to create records directly in the public_zone set to ""
  # otherwise it must end in a period
  bod_public_subdomain = "bod."

  # DNS zone calculations based on requested instances.  The numbers
  # represent the count of IP addresses in a subnet.
  #
  # NOTE: there is an assumption that subnets are /24 in the reverse
  # zone names.

  # Port Scanners DNS entries
  count_port_scanner = "${local.nmap_instance_count}"

  # Vulnerability Scanners DNS entries
  count_vuln_scanner = "${local.nessus_instance_count}"

  # Database DNS entries
  count_database = "${local.mongo_instance_count}"
}
