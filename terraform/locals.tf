locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "production"
  production_workspace = "${replace(terraform.workspace, "production", "") != terraform.workspace}"

  # TODO no dynamic workspace until we can loop modules (see below)
  nmap_instance_count = "2"   #"${local.production_workspace ? 32 : 1}"
  nessus_instance_count = "2" #"${local.production_workspace ? 4 : 1}"
  mongo_instance_count = "1"

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

  # divy up the subnets
  # NOTE: there is an assumption that they are /24
  first_port_scanner = 11
  count_port_scanner = 100
  first_vuln_scanner = 201
  count_vuln_scanner = 10
  first_database = 11
  count_database = 4
  the_commander = 5 # there can be only one
  the_bastion = 254 # there can be only one
}
