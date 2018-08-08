variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default = "us-east-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default = "a"
}

variable "tags" {
  type = "map"
  default = {}
  description = "Tags to apply to all AWS resources created"
}

variable "rules_bucket_name" {
  description = "The name of the bucket to store egress IP addresses"
  default = "s3-cdn.rules.ncats.cyber.dhs.gov"
}
