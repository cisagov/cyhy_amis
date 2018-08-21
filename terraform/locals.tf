locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "production"
  production_workspace = "${replace(terraform.workspace, "production", "") != terraform.workspace}"

  # TODO no dynamic workspace until we can loop modules (see below)
  nmap_instance_count = "2"   #"${local.production_workspace ? 32 : 1}"
  nessus_instance_count = "2" #"${local.production_workspace ? 4 : 1}"
  mongo_instance_count = "1"  # TODO: stuck at one until we can scale mongo_ec2

  # These are the ports via which trusted networks are allowed to
  # access the public-facing CyHy hosts
  cyhy_trusted_ingress_ports = [
    22,
    8834
  ]

  # Pretty obvious what this is
  tcp_and_udp = [
    "tcp",
    "udp"
  ]

  # domain name to use for internal DNS
  private_domain = "local"

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
  the_commander = 5 # there can be only one
  the_bastion = 254 # there can be only one
}
