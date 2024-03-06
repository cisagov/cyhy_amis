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
data "aws_default_tags" "default" {}

locals {
  # Determine if this is a Production workspace by checking
  # if terraform.workspace begins with "prod"
  production_workspace = length(regexall("^prod", terraform.workspace)) == 1

  bod_lambda_types = toset(keys(var.bod_lambda_functions))

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

  # Get the public IPs associated with our nessus instances.
  # Since our elastic IPs are handled differently in
  # production vs. non-production workspaces, their corresponding
  # Terraform resources (data.aws_eip.cyhy_nessus_eips,
  # data.aws_eip.cyhy_nessus_random_eips) may or may not be created.  To
  # handle that, we use coalescelist() to choose the (non-empty) list
  # containing the valid eip objects.
  nessus_public_ips = coalescelist(
    data.aws_eip.cyhy_nessus_eips,
    aws_eip.cyhy_nessus_random_eips,
  )

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

  # This base will be used by all instances for their CloudWatch Agent
  # configuration
  cloudwatch_agent_log_group_base = "/instance-logs/${terraform.workspace}"
  # CloudWatch Agent log group name base for cyhy instances
  cyhy_cloudwatch_agent_log_group_base = "${local.cloudwatch_agent_log_group_base}/${local.cyhy_private_domain}"
  # CloudWatch Agent log group name base for bod instances
  bod_cloudwatch_agent_log_group_base = "${local.cloudwatch_agent_log_group_base}/${local.bod_private_domain}"

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

  # This is necessary since aws_instance.cyhy_mongo uses count, but we
  # don't want the kevsync and nvdsync alarm resources to depend on
  # the order of the database instances.  On the other hand, we _do_
  # need to use the index of the instance into aws_instance.cyhy_mongo
  # to reconstruct the hostname.
  db_instance_hostnames = toset([
    for index in range(var.mongo_instance_count) :
    "database${index + 1}.${aws_route53_zone.cyhy_private_zone.name}"
  ])
}
