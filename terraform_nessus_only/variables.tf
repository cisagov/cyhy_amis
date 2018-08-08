variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default = "us-east-1"
  # Currently we need to use us-east-1a because we are using a subnet in the
  # default VPC, and that subnet resides in us-east-1a
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default = "a"
}

variable "tags" {
  type = "map"
  default = {
    Team = "NCATS OIS - Development"
    Application = "Manual Cyber Hygiene"
  }
  description = "Tags to apply to all AWS resources created"
}

variable "default_aws_subnet_id" {
  description = "The id of one of the subnets in the default AWS VPC"
  default = ""
}

# This should be overridden by a production.tfvars file,
# most-likely stored outside of version control
variable "trusted_ingress_networks_ipv4" {
  type = "list"
  default = [ "0.0.0.0/0" ]
}

variable "trusted_ingress_networks_ipv6" {
  type = "list"
  default = [ "::/0" ]
}
