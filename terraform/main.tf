# Configure AWS
provider "aws" {
  region = var.aws_region
}

# This is the provider that can make changes to DNS entries
# in the public cyber.dhs.gov zone.
#
# NOTE: After the CyHy AWS account moves into the COOL, it will be possible
# to assume the role below via Terraform remote state.  For details see:
# https://github.com/cisagov/pca-teamserver-aws/pull/30#discussion_r400610194
provider "aws" {
  alias   = "public_dns"
  profile = "cool-dns-route53resourcechange-cyber.dhs.gov"
  region  = var.aws_region
}

# The AWS account ID being used
data "aws_caller_identity" "current" {
}

# The list of available AWS availability zones
data "aws_availability_zones" "all" {
}
