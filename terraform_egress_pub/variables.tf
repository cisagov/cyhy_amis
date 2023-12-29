# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
#
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "aws_availability_zone" {
  default     = "a"
  description = "The AWS availability zone to deploy into (e.g. a, b, c, etc.)."
  type        = string
}

variable "aws_region" {
  default     = "us-east-1"
  description = "The AWS region to deploy into (e.g. us-east-1)."
  type        = string
}

variable "distribution_domain" {
  default     = "rules.ncats.cyber.dhs.gov"
  description = "The domain name of the CloudFront distribution and certificate."
  type        = string
}

variable "distribution_oac_description" {
  default     = "Allow CloudFront to read from the rules bucket."
  description = "The description to apply to the CloudFront Origin Access Control."
  type        = string
}

variable "distribution_oac_name" {
  default     = "rules-s3-distribution"
  description = "The name for the CloudFront Origin Access Control."
  type        = string
}

variable "root_object" {
  default     = "all.txt"
  description = "The root object to serve when no path is provided, or an error occurs."
  type        = string
}

variable "rules_bucket_name" {
  default     = "s3-cdn.rules.ncats.cyber.dhs.gov"
  description = "The name of the bucket to store egress IP addresses."
  type        = string
}

variable "tags" {
  default     = {}
  description = "Tags to apply to all AWS resources created."
  type        = map(string)
}
