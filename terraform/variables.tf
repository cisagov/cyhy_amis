variable "aws_region" {
  description = "The AWS region to deploy into (e.g. us-east-1)."
  default = "us-east-1"
}

variable "tags" {
  type = "map"
  default = {}
  description = "Tags to apply to all AWS resources created"
}
