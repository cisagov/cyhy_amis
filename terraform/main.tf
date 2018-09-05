# Configure AWS
provider "aws" {
  region = "${var.aws_region}"
}

# The AWS account ID being used
data "aws_caller_identity" "current" {}

# The list of available AWS availability zones
data "aws_availability_zones" "all" {}
