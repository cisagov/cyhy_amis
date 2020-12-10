variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  default     = "a"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all AWS resources created"
}

variable "rules_bucket_name" {
  description = "The name of the bucket to store egress IP addresses"
  default     = "s3-cdn.rules.ncats.cyber.dhs.gov"
}

variable "distribution_domain" {
  description = "The domain name of the cloudfront distribution and certificate."
  default     = "rules.ncats.cyber.dhs.gov"
}

variable "root_object" {
  description = "The root object to serve when no path is provided, or an error occurs"
  default     = "all.txt"
}
