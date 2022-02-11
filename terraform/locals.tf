# The list of available AWS availability zones
data "aws_availability_zones" "all" {}

# The AWS account ID being used
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# Retrieve the default tags for the default provider.  These are
# used to create volume tags for EC2 instances, since volume_tags does
# not yet inherit the default tags from the provider.  See
# hashicorp/terraform-provider-aws#19188 for more details.
# ------------------------------------------------------------------------------
data "aws_default_tags" "default" {
  provider = aws
}

locals {
  # This is a goofy but necessary way to determine if
  # terraform.workspace contains the substring "prod"
  production_workspace = replace(terraform.workspace, "prod", "") != terraform.workspace

  # Note: some locals are generated dynamically by the configure.py script and
  # are not part of this file.  e.g.; *_instance_count  Please run configure.py
  # to generate these in a separate file.

  # These are the ports via which trusted networks are allowed to
  # access the public-facing CyHy hosts
  cyhy_trusted_ingress_ports = [
    22,
    8834,
  ]

  # These are the port ranges via which anyone is allowed to
  # access the public-facing CyHy hosts
  cyhy_untrusted_ingress_port_ranges = [
    {
      start = 1
      end   = 21
    },
    {
      start = 23
      end   = 8833
    },
    {
      start = 8835
      end   = 65535
    },
  ]

  # These are the ports on which the BOD Docker security group is
  # allowed to egress anywhere
  bod_docker_egress_anywhere_ports = [
    21,
    80,
    443,
  ]

  # These are the ports on which the BOD Lambda security group is
  # allowed to egress anywhere
  bod_lambda_egress_anywhere_ports = [
    25,
    80,
    443,
    465,
    587,
  ]

  # These are the ports via which trusted networks are allowed to
  # access the Management hosts on the private subnet
  mgmt_trusted_ingress_ports = [
    22,
    8834,
  ]

  # These are the ports on which the Management scanner security group
  # is allowed to egress anywhere
  mgmt_scanner_egress_anywhere_ports = [
    443,
  ]

  # Pretty obvious what these are
  tcp_and_udp = [
    "tcp",
    "udp",
  ]
  ingress_and_egress = [
    "ingress",
    "egress",
  ]

  # domain names to use for internal DNS
  cyhy_private_domain = "cyhy"
  bod_private_domain  = "bod"
  mgmt_private_domain = "mgmt"

  # subdomains to use in the public_zone.
  # to create records directly in the public_zone set to ""
  # otherwise it must end in a period
  cyhy_public_subdomain = "cyhy.ncats."

  # subdomains to use in the public_zone.
  # to create records directly in the public_zone set to ""
  # otherwise it must end in a period
  bod_public_subdomain  = "bod.ncats."
  mgmt_public_subdomain = "mgmt.ncats."

  # DNS zone calculations based on requested instances.  The numbers
  # represent the count of IP addresses in a subnet.
  #
  # NOTE: there is an assumption that subnets are /24 or smaller in
  # the reverse zone names.

  # Port Scanners DNS entries
  count_port_scanner = var.nmap_instance_count

  # Vulnerability Scanners DNS entries
  count_vuln_scanner = var.nessus_instance_count

  # Database DNS entries
  count_database = var.mongo_instance_count

  # Management Vulnerability Scanner DNS entries
  count_mgmt_vuln_scanner = var.mgmt_nessus_instance_count
}
