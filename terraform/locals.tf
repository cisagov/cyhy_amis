locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "production"
  production_workspace = "${replace(terraform.workspace, "production", "") != terraform.workspace}"

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

  # first IP of the nmap instance in the scanner subnet
  first_port_scanner = 11
  count_port_scanner = 100
}
