# Configure AWS
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# This is the provider that can make changes to DNS entries
# in the public cyber.dhs.gov zone.
#
# NOTE: After the CyHy AWS account moves into the COOL, it will be possible
# to assume the role below via Terraform remote state.  For details see:
# https://github.com/cisagov/pca-teamserver-aws/pull/30#discussion_r400610194
provider "aws" {
  alias = "public_dns"

  profile = "cool-dns-route53resourcechange-cyber.dhs.gov"
  region  = var.aws_region

  default_tags {
    tags = var.tags
  }
}
